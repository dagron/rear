
module RearTest__CRUD
  class App < E
    include Rear
    model Book
  end

  Spec.new App do
    orm = RearORM.new(app.model, app.pkey)

    Should 'create new item' do
      name, about = random_string, random_string
      post :crud, name: name, about: about
      is(last_response).ok?
      id = last_response.body.to_i

      item = orm[id]
      check(item).instance_of?(app.model)
      expect(item.id) == id
      expect(item.name.to_s) == name
      expect(item.about.to_s) == about

      Then 'update it' do
        new_name = random_string
        put :crud, id, name: new_name
        is(last_response).ok?

        item.reload
        refute(item.name.to_s) == name
        check(item.name.to_s) == new_name
      end

      And 'finally delete it' do
        delete :crud, id
        is(last_response).ok?
        item = app[id]
        is(item).nil?
      end
    end

    Testing 'multiple delete' do

      ids = (1..10).inject([]) {|f,c| post(:crud); f << last_response.body.to_i}
      expect(ids.size) == 10
      items = orm.filter(conditions: {app.pkey => ids})
      expect(items.size) == ids.size

      delete :delete_selected, items: ids.join(' ')
      is(last_response).ok?
      items =  orm.filter(conditions: {app.pkey => ids})
      expect(items.size) == 0
    end

  end

  class ReadOnlyBook < E
    include Rear
    model Book
    readonly!
  end
  Spec.new ReadOnlyBook do
    book, book_id = new_book

    Should 'Prohibit items creation' do
      name, about = random_string, random_string
      post :crud, name: name, about: about
      is(last_response).readonly_error?
    end

    Should 'prohibit updates' do
      put :crud, book_id, name: random_string
      is(last_response).readonly_error?
    end

    Should 'prohibit deletion' do
      delete :crud, book_id
      is(last_response).readonly_error?
    end

  end
end
