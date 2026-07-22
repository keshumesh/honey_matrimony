#!/bin/bash

# Test PDF Import Script
# Usage: bash test_pdf_import.sh /path/to/pdf/file.pdf

PDF_FILE=$1

if [ -z "$PDF_FILE" ]; then
  echo "Usage: bash test_pdf_import.sh /path/to/file.pdf"
  exit 1
fi

cd "$(dirname "$0")"

# Run Rails console command
rails console << EOF
require 'pdf/reader'

pdf_path = "$PDF_FILE"
puts "Testing PDF: #{pdf_path}"
puts "File exists: #{File.exist?(pdf_path)}"

reader = PDF::Reader.new(pdf_path)
puts "PDF pages: #{reader.pages.length}"

text = ""
reader.pages.each do |page|
  text += page.text + "\n"
end

puts "\n=== EXTRACTED TEXT (first 1000 chars) ==="
puts text[0..1000]

puts "\n=== PARSING AS MATRIMONY PROFILE ==="
importer = PdfImportService.new(pdf_path)
matrimony_records = importer.send(:parse_matrimony_profiles, text)

puts "Records found: #{matrimony_records.length}"
matrimony_records.each do |record|
  puts "\nRecord: #{record[:name]}"
  puts "  DOB: #{record[:dob]}"
  puts "  Mobile: #{record[:mobile_no]}"
  puts "  Email: #{record[:email]}"
end

EOF
