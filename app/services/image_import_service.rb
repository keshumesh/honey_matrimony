class ImageImportService
  attr_reader :errors, :created_users, :extracted_text, :ocr_available

  def initialize(file_path_or_text = "")
    @file_path = file_path_or_text if File.exist?(file_path_or_text.to_s)
    @text_input = file_path_or_text if !@file_path && file_path_or_text.present?
    @extracted_text = @text_input.to_s
    @errors = []
    @created_users = []
    @ocr_available = check_ocr_available
  end

  def import
    if @file_path
      # File-based import with OCR
      unless @ocr_available
        @errors << "Tesseract OCR is not installed. Please paste the extracted text instead, or install Tesseract."
        return false
      end
      
      extract_text_from_image
      
      if @extracted_text.blank?
        @errors << "No text could be extracted from the image. Please ensure the image is clear and readable."
        return false
      end
    elsif @text_input.blank?
      @errors << "Please provide either an image file or extracted text."
      return false
    end

    begin
      Rails.logger.info "Processing text: #{@extracted_text[0..500]}"
      
      # Try parsing as matrimony profile first, then as CSV
      matrimony_records = parse_matrimony_profiles(@extracted_text)
      
      Rails.logger.info "Matrimony records found: #{matrimony_records.length}"
      
      if matrimony_records.any?
        matrimony_records.each { |record| create_user_from_matrimony(record) }
      else
        # Fall back to CSV format
        csv_records = parse_csv_format(@extracted_text)
        Rails.logger.info "CSV records found: #{csv_records.length}"
        
        if csv_records.any?
          csv_records.each { |record| create_user_from_data(record) }
        else
          @errors << "No valid user data found in image text. Please check the image quality and content."
          return false
        end
      end
      
      true
    rescue StandardError => e
      Rails.logger.error "Text import error: #{e.message}\n#{e.backtrace.join("\n")}"
      @errors << "Error processing text: #{e.message}"
      false
    end
  end

  private

  def check_ocr_available
    begin
      require 'rtesseract'
      true
    rescue LoadError
      false
    end
  end

  def extract_text_from_image
    begin
      Rails.logger.info "Extracting text from image: #{@file_path}"
      
      # Load rtesseract (should be available since ocr_available was true in initialize)
      require 'rtesseract'
      
      # Use Tesseract OCR to extract text
      image = RTesseract.new(@file_path, lang: 'eng')
      @extracted_text = image.to_s.strip
      
      Rails.logger.info "Extracted text (first 500 chars): #{@extracted_text[0..500]}"
    rescue LoadError => e
      Rails.logger.error "RTesseract not available: #{e.message}"
      @errors << "OCR library not loaded. Please install Tesseract OCR and run 'bundle install'."
      @extracted_text = ""
    rescue StandardError => e
      Rails.logger.error "OCR Error: #{e.message}"
      @errors << "OCR Error: #{e.message}. Make sure Tesseract is installed."
      @extracted_text = ""
    end
  end

  def parse_matrimony_profiles(text)
    records = []
    
    lines = text.split("\n").map(&:strip)
    
    # Check if this looks like a matrimony profile
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
        in_personal_details = false
      elsif line.include?(":")
        key, value = line.split(":", 2).map(&:strip)
        key_lower = key.downcase
        
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
        current_record[:mobile_no] = line unless current_record[:mobile_no]
      end
    end
    
    if current_record.present? && (current_record[:name].present? || current_record[:dob].present?)
      records << current_record
    end
    
    records.reject { |r| r[:name].blank? && r[:dob].blank? }
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
    if line.include?(":")
      parse_colon_format(line)
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

  def parse_date(date_string)
    Date.parse(date_string)
  rescue
    nil
  end

  def create_user_from_matrimony(profile_data)
    name_parts = profile_data[:name]&.split
    return if name_parts.blank?

    first_name = name_parts.first
    last_name = name_parts.drop(1).join(" ") || "User"
    
    email = profile_data[:email] || "#{first_name.downcase}.#{last_name.downcase}@matrimony.local".gsub(" ", "_")
    mobile_no = profile_data[:mobile_no] || "0000000000"
    
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
    return if user_data[:role].blank? || !["admin", "manager"].include?(user_data[:role])

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
