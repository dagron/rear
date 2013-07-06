module EASpecHelpers
  
  def new_book data = {}
    data = {name: random_string, about: random_string}.merge(data)
    item = Book.create(data)
    item_id = item[:id].to_i
    check(item_id) > 0
    [item, item_id]
  end

  def count_books conditions = nil
    args = conditions ? [{conditions: conditions}] : []
    RearORM.new(Book).count *args
  end

  def extract_elements selector = nil
    selector ||= last_request.env['PATH_INFO'] =~ /\/+edit\/+\d+/ ? 
      '.editor-column_value' : '.pane-column_value'
    doc = Nokogiri::HTML(last_response.body)
    columns = doc.css(selector)
    columns
  end

  def readonly_error? last_response
    is(last_response).client_error?
    does(last_response.body) =~ /readonly/i
  end

  def random_string
    ('A'..'Z').to_a.sample(5).join + [rand.to_s, rand.to_s].sample
  end
  
end
