# frozen_string_literal: true

require 'open-uri'

When(/^захожу на страницу "([^"]*)"$/) do |url|
  visit url
  $logger.info("Страница #{url} открыта")
end

And(/^перехожу на вкладку "([^"]*)"$/) do |url|
  visit url
  $logger.info("Перешёл на вкладку #{url}")
end

And(/^скачиваю последний стабильный релиз Ruby$/) do
  stable_section = find(:xpath, "//*[contains(text(), 'Стабильные релизы')]")
  link = stable_section.find(:xpath, ".//following::a[contains(text(), 'Ruby')][1]")

  @release_name = link.text.match(/Ruby ([\d.]+)/)[1]
  href = link[:href]
  @file_name = File.basename(URI.parse(href).path)
  download_dir = File.expand_path('~/Загрузки')
  @download_path = File.join(download_dir, @file_name)

  FileUtils.mkdir_p(download_dir)

  $logger.info("Релиз: Ruby #{@release_name}, ссылка: #{href}")

  URI.open(href, 'rb') do |remote|
    File.open(@download_path, 'wb') {|f| f.write(remote.read)}
  end

  $logger.info("Файл #{@file_name} скачан в #{@download_path}")
end

Then(/^файл должен быть в директории загрузок$/) do
  expect(File.exist?(@download_path)).to be true
end

And(/^имя файла должно совпадать с именем релиза на сайте$/) do
  expect(@file_name).to include(@release_name)
end
