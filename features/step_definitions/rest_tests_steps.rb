# frozen_string_literal: true

When(/^получаю информацию о пользователях$/) do
  users_full_information = $rest_wrap.get('/users')

  $logger.info('Информация о пользователях получена')
  @scenario_data.users_full_info = users_full_information
end

When(/^проверяю (наличие|отсутствие) логина (\w+\.\w+) в списке пользователей$/) do |presence, login|
  search_login_in_list = true
  presence == 'отсутствие' ? search_login_in_list = !search_login_in_list : search_login_in_list

  logins_from_site = @scenario_data.users_full_info.map { |f| f.try(:[], 'login') }
  login_presents = logins_from_site.include?(login)

  if login_presents
    message = "Логин #{login} присутствует в списке пользователей"
    search_login_in_list ? $logger.info(message) : raise(message)
  else
    message = "Логин #{login} отсутствует в списке пользователей"
    search_login_in_list ? raise(message) : $logger.info(message)
  end
end

When(/^добавляю пользователя c логином (\w+\.\w+) именем (\w+) фамилией (\w+) паролем ([\d\w@!#]+)$/) do
|login, name, surname, password|

  response = $rest_wrap.post('/users', login: login,
                                       name: name,
                                       surname: surname,
                                       password: password,
                                       active: 1)
  $logger.info(response.inspect)
end

When(/^добавляю пользователя с параметрами:$/) do |data_table|
  user_data = data_table.raw

  login = user_data[0][1]
  name = user_data[1][1]
  surname = user_data[2][1]
  password = user_data[3][1]

  step "добавляю пользователя c логином #{login} именем #{name} фамилией #{surname} паролем #{password}"
end

When(/^нахожу пользователя с логином (\w+\.\w+)$/) do |login|
  step %(получаю информацию о пользователях)
  if @scenario_data.users_id[login].nil?
    @scenario_data.users_id[login] = find_user_id(users_information: @scenario_data
                                                                         .users_full_info,
                                                  user_login: login)
  end

  $logger.info("Найден пользователь #{login}")
end


# Методы изменения и удаления:

When(/^изменяю пользователя с логином (\w+\.\w+) именем (\w+) фамилией (\w+)$/) do |login, name, surname|
  user_id = @scenario_data.users_id[login] || find_user_id(
    users_information: @scenario_data.users_full_info,
    user_login: login
  )

  old_user = @scenario_data.users_full_info.find{|u| u['login'] == login}
  old_name = old_user['name']
  old_surname = old_user['surname']

  $rest_wrap.put("/users/#{user_id}", name: name, surname: surname)

  $logger.info("Пользователь #{login} обновлён: имя '#{old_name}' → '#{name}', фамилия '#{old_surname}' → '#{surname}'")
end

Then(/^проверяю, что у пользователя с логином (\w+\.\w+) имя равно (\w+) и фамилия равна (\w+)$/) do |login, expected_name, expected_surname|
  users_full_information = $rest_wrap.get('/users')
  user = users_full_information.find{|u| u['login'] == login}

  actual_name = user['name']
  actual_surname = user['surname']

  if actual_name == expected_name && actual_surname == expected_surname
    $logger.info("Проверка пройдена: у пользователя #{login} имя '#{actual_name}', фамилия '#{actual_surname}'")
  else
    $logger.warn("Несоответствие для пользователя #{login}: имя фактическое '#{actual_name}' (ожидалось '#{expected_name}'),
фамилия фактическая '#{actual_surname}' (ожидалось '#{expected_surname}')")
  end
end

When(/^удаляю пользователя с логином (\w+\.\w+)$/) do |login|
  user = @scenario_data.users_full_info.find{|u| u['login'] == login}
  if user
    $rest_wrap.delete("/users/#{user['id']}")
    $logger.info("Пользователь #{login} удалён.")
  else
    $logger.warn("Попытка удалить несуществующего пользователя #{login}")
  end

  @scenario_data.users_full_info = $rest_wrap.get('/users')
end
