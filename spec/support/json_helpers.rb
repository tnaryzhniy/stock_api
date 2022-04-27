module JSONHelpers
  def response_body
    JSON.parse(response.body)
  end

  def response_error
    response_body['error']
  end
end
