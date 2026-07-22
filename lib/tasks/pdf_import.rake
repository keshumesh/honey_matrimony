namespace :pdf_import do
  desc "Test PDF import parsing"
  task :test, [:file_path] => :environment do |t, args|
    file_path = args[:file_path]
    
    unless file_path
      puts "Usage: rake pdf_import:test[path/to/file.pdf]"
      exit 1
    end
    
    unless File.exist?(file_path)
      puts "File not found: #{file_path}"
      exit 1
    end
    
    puts "=" * 60
    puts "Testing PDF Import: #{file_path}"
    puts "=" * 60
    
    begin
      require 'pdf/reader'
      
      reader = PDF::Reader.new(file_path)
      puts "\n✓ PDF file opened successfully"
      puts "  Pages: #{reader.pages.length}"
      
      text = ""
      reader.pages.each do |page|
        text += page.text + "\n"
      end
      
      puts "\n✓ Text extracted"
      puts "  Length: #{text.length} characters"
      puts "\nFirst 500 characters:"
      puts "-" * 60
      puts text[0..500]
      puts "-" * 60
      
      puts "\n" + "=" * 60
      puts "Parsing as Matrimony Profile..."
      puts "=" * 60
      
      importer = PdfImportService.new(file_path)
      matrimony_records = importer.send(:parse_matrimony_profiles, text)
      
      puts "\n✓ Parsing complete"
      puts "  Records found: #{matrimony_records.length}"
      
      if matrimony_records.any?
        matrimony_records.each_with_index do |record, idx|
          puts "\n" + "-" * 60
          puts "Record #{idx + 1}:"
          puts "-" * 60
          record.each do |key, value|
            next if value.blank?
            puts "  #{key}: #{value}"
          end
        end
      else
        puts "\n✗ No matrimony records found"
        puts "\nChecking for CSV format..."
        csv_records = importer.send(:parse_csv_format, text)
        puts "  CSV records found: #{csv_records.length}"
      end
      
    rescue StandardError => e
      puts "\n✗ Error: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end
