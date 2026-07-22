require "pdf/reader"

class PdfImportService
  attr_reader :errors, :created_users, :extracted_data

  def initialize(file_path)
    @file_path = file_path
    @errors = []
    @created_users = []
    @extracted_data = []
  end

  def import
    unless File.exist?(@file_path)
      @errors << "File not found"
      return false
    end

    begin
      reader = PDF::Reader.new(@file_path)
      text = extract_text_from_pdf(reader)
      
      # Log extracted text for debugging
      Rails.logger.info "PDF Text extracted: #{text[0..500]}"
      
      # Try parsing as matrimony profile first, then as CSV
      matrimony_records = parse_matrimony_profiles(text)
      
      Rails.logger.info "Matrimony records found: #{matrimony_records.length}"
      
      if matrimony_records.any?
        @extracted_data = matrimony_records
        matrimony_records.each { |record| create_user_from_matrimony(record) }
      else
        # Fall back to CSV format
        csv_records = parse_csv_format(text)
        Rails.logger.info "CSV records found: #{csv_records.length}"
        
        if csv_records.any?
          csv_records.each { |record| create_user_from_data(record) }
        else
          @errors << "No valid user data found in PDF. Please check the file format."
          return false
        end
      end
      
      true
    rescue StandardError => e
      Rails.logger.error "PDF import error: #{e.message}\n#{e.backtrace.join("\n")}"
      @errors << "Error reading PDF: #{e.message}"
      false
    end
  end

  private

  def extract_text_from_pdf(reader)
    text = ""
    reader.pages.each do |page|
      text += page.text + "\n"
    end
    text
  end

  def parse_matrimony_profiles(text)
    records = []
    
    lines = text.split("\n").map(&:strip)
    
    # Check if this looks like a matrimony profile PDF
    # by looking for common matrimony demographic fields
    matrimony_keywords = ["date of birth", "caste", "complexion", "height", "occupation", "mother tongue", "education"]
    has_matrimony_fields = matrimony_keywords.any? { |keyword| text.downcase.include?(keyword) }
    
    return [] unless has_matrimony_fields
    
    current_record = {}
    current_name = nil
    in_personal_details = false
    
    lines.each_with_index do |line, idx|
      next if line.blank? || line.include?("||") || line.downcase.include?("shree ganesh")
      
      # Personal Details section marker
      if line.downcase.include?("personal details")
        # Save previous record if exists
        if current_record.present? && (current_record[:name].present? || current_record[:dob].present?)
          records << current_record
        end
        
        # Start new record - look backward for the name
        current_name = nil
        prev_idx = idx - 1
        while prev_idx >= 0
          prev_line = lines[prev_idx].strip
          if prev_line.present? && !prev_line.include?(":") && !prev_line.include?("||") && 
             !prev_line.match?(/^\d+$/) && !prev_line.downcase.include?("sarai") && prev_line.length > 2
            current_name = prev_line
            break
          end
          prev_idx -= 1
        end
        
        current_record = { name: current_name }
        in_personal_details = true
      elsif line.downcase.include?("family details") || line.downcase.include?("uncles") || line.downcase.include?("siblings")
        # End of personal section
        in_personal_details = false
      elsif line.include?(":")
        key, value = line.split(":", 2).map(&:strip)
        key_lower = key.downcase
        
        # Only parse fields that are clearly part of a profile
        if in_personal_details || matrimony_keywords.any? { |kw| key_lower.include?(kw) }
          case key_lower
          when "date of birth"
            current_record[:dob] = parse_date(value)
          when "caste"
            current_record[:caste] = value
          when "baan"
            current_record[:ban] = value
          when "complexion"
            current_record[:complexion] = value
          when "height"
            current_record[:height] = value
          when "education"
            current_record[:education] = value
          when "occupation"
            current_record[:occupation] = value
          when "address"
            current_record[:address] = value
          when "phone", "mobile", "mobile_no"
            digits = value.gsub(/\D/, '')
            current_record[:mobile_no] = digits if digits.length >= 10
          when "email"
            current_record[:email] = value
          when "religion"
            current_record[:religion] = value
          when "mother tongue"
            current_record[:mother_tongue] = value
          when "gender"
            current_record[:gender] = value
          end
        end
      elsif line.match?(/^\d{10}$/) && (current_record.present? || in_personal_details)
        # Standalone 10-digit phone number
        current_record[:mobile_no] = line unless current_record[:mobile_no]
      end
    end
    
    # Save last record
    if current_record.present? && (current_record[:name].present? || current_record[:dob].present?)
      records << current_record
    end
    
    # Filter to only records with at least a name or DOB
    records.reject { |r| r[:name].blank? && r[:dob].blank? }
  end

  def parse_date(date_string)
    Date.parse(date_string)
  rescue
    nil
  end

  def parse_csv_format(text)
    records = []
    lines = text.split("\n").reject(&:blank?)
    
    lines.each do |line|
      user_data = parse_user_line(line)
      records << user_data if user_data.present?
    end
    
    records
  end

  def parse_user_line(line)
    # Try parsing comma-separated with colons format
    if line.include?(":")
      parse_colon_format(line)
    # Try parsing pipe-separated format
    elsif line.include?("|")
      parse_pipe_format(line)
    else
      nil
    end
  end

  def parse_colon_format(line)
    data = {}
    pairs = line.split(",").map(&:strip)

    pairs.each do |pair|
      key, value = pair.split(":", 2).map(&:strip)
      case key.downcase
      when "first name", "first_name", "firstname"
        data[:first_name] = value
      when "last name", "last_name", "lastname"
        data[:last_name] = value
      when "email"
        data[:email] = value
      when "mobile", "mobile_no", "phone", "phone_number"
        data[:mobile_no] = value
      when "password"
        data[:password] = value
      when "role"
        data[:role] = value&.downcase
      end
    end

    data.any? ? data : nil
  end

  def parse_pipe_format(line)
    parts = line.split("|").map(&:strip)
    return nil if parts.length < 6

    {
      first_name: parts[0],
      last_name: parts[1],
      email: parts[2],
      mobile_no: parts[3],
      password: parts[4],
      role: parts[5]&.downcase
    }
  end

  def create_user_from_matrimony(profile_data)
    # For matrimony profiles, we extract what we can
    # Email and password will be auto-generated
    
    name_parts = profile_data[:name]&.split
    return if name_parts.blank?

    first_name = name_parts.first
    last_name = name_parts.drop(1).join(" ") || "User"
    
    # Generate a default email from name if not provided
    email = profile_data[:email] || "#{first_name.downcase}.#{last_name.downcase}@matrimony.local".gsub(" ", "_")
    mobile_no = profile_data[:mobile_no] || "0000000000"
    
    # Generate a default password
    default_password = "TempPass@2026"
    
    user = User.new(
      first_name: first_name,
      last_name: last_name,
      email: email,
      mobile_no: mobile_no,
      password: default_password,
      password_confirmation: default_password,
      role: "user",
      gender: profile_data[:gender] || "Not Specified",
      dob: profile_data[:dob],
      caste: profile_data[:caste] || "Not Specified",
      ban: profile_data[:ban] || "Not Specified",
      complexion: profile_data[:complexion] || "Not Specified",
      height: profile_data[:height] || "Not Specified",
      highest_educational_details: profile_data[:education] || "Not Specified",
      job: profile_data[:occupation] || "Not Specified",
      address: profile_data[:address],
      religion: profile_data[:religion] || "Not Specified",
      mother_tongue: profile_data[:mother_tongue] || "Not Specified",
      marital_status: "Unmarried",
      food_type: "Vegetarian",
      manglik: "No",
      skip_matrimony_validation: true
    )

    if user.save
      @created_users << user
    else
      @errors << "Failed to create user #{email}: #{user.errors.full_messages.join(', ')}"
    end
  end

  def create_user_from_data(user_data)
    # Validate role
    return if user_data[:role].blank? || ![ "admin", "manager" ].include?(user_data[:role])

    # Validate required fields
    return if user_data[:first_name].blank? || user_data[:email].blank? || user_data[:password].blank?

    user = User.new(
      first_name: user_data[:first_name],
      last_name: user_data[:last_name] || "User",
      email: user_data[:email],
      mobile_no: user_data[:mobile_no] || "0000000000",
      password: user_data[:password],
      password_confirmation: user_data[:password],
      role: user_data[:role],
      gender: "Not Specified",
      skip_matrimony_validation: true
    )

    if user.save
      @created_users << user
    else
      @errors << "Failed to create user #{user_data[:email]}: #{user.errors.full_messages.join(', ')}"
    end
  end
end
