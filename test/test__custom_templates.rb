
module RearTest__CustomTemplates

  class SharedTemplates < E
    include Rear
    model Book
    rear_templates 'templates/shared'
    ipp 1000
  end
  Spec.new self do
    app E.new {
      mount SharedTemplates
      root File.expand_path('..', __FILE__)
    }
    map SharedTemplates.base_url

    item, item_id = new_book

    Testing :pane do
      get
      is(last_response).ok?
      expect( extract_elements ).any? {|e|
        e.children.any? {|c|
          c.to_s == '<p class="custom-shared-template">%s</p>' % item[:name]
        }
      }
    end

    Testing :editor do
      get :edit, item_id
      is(last_response).ok?
      expect( extract_elements ).any? { |e|
        e.children.any? {|c| 
          c.to_s == '<input class="custom-shared-template" value="%s">' % item[:name]
        }
      }
    end
  end

  class AdhocDefaultTemplate < E
    include Rear
    model Book
    rear_templates 'templates/adhoc'
    ipp 1000
  end
  Spec.new self do
    app E.new {
      mount AdhocDefaultTemplate
      root File.expand_path('..', __FILE__)
    }
    map AdhocDefaultTemplate.base_url

    item, item_id = new_book

    Testing :pane do
      get
      is(last_response).ok?
      expect( extract_elements ).any? {|e|
        e.children.any? {|c|
          c.to_s == '<p class="adhoc-default-template">%s</p>' % item[:name]
        }
      }
    end

    Testing :editor do
      get :edit, item_id
      is(last_response).ok?
      expect( extract_elements ).any? { |e|
        e.children.any? {|c| 
          c.to_s == '<input class="adhoc-default-template" value="%s">' % item[:name]
        }
      }
    end
  end

  class AdhocGivenTemplate < E
    include Rear
    model Book
    rear_templates 'templates/adhoc'
    input :name do
      editor_template :name
      pane_template   :name
    end
    ipp 1000
  end
  Spec.new self do
    app E.new {
      mount AdhocGivenTemplate
      root File.expand_path('..', __FILE__)
    }
    map AdhocGivenTemplate.base_url

    item, item_id = new_book

    Testing :pane do
      get
      is(last_response).ok?
      expect( extract_elements ).any? {|e|
        e.children.any? {|c|
          c.to_s == '<p class="adhoc-given-template">%s</p>' % item[:name]
        }
      }
    end

    Testing :editor do
      get :edit, item_id
      is(last_response).ok?
      expect( extract_elements ).any? { |e|
        e.children.any? {|c| 
          c.to_s == '<input class="adhoc-given-template" value="%s">' % item[:name]
        }
      }
    end
  end


  class ProcTemplate < E
    include Rear
    model Book
    input :name do
      pane_template   { item.name  }
      editor_template { item.about }
    end
  end
  Spec.new ProcTemplate do
  
    item, item_id = new_book()

    Testing :pane do
      get
      is(last_response).ok?
      expect( extract_elements ).any? {|e| 
        e.children.any? {|c| c.to_s == item[:name]}
      }
    end

    Testing :editor do
      get :edit, item_id
      is(last_response).ok?
      expect( extract_elements ).any? do |e|
        e.children.any? {|c| 
          c.to_s == item[:about]
        }
      end
    end
  end
end
