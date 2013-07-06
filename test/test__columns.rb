
module RearTest__Columns

  class BasicApp < E
    include Rear
    model Book
  end
  Spec.new BasicApp do

    item, item_id = new_book()

    Testing :pane do
      get
      is(last_response).ok?
      expect(extract_elements('.pane-item').size) > 0

      elements = extract_elements
      expect( elements ).any? {|e| e.text == item[:name].to_s }
      expect( elements ).any? {|e| e.text == item[:about].to_s}
    end

    Testing :editor do
      get :edit, item_id
      is(last_response).ok?
      elements = extract_elements
      expect( elements ).any? do |e|
        e.children.any? {|c| c.name == 'input' && c.attr(:value) == item[:name].to_s }
      end
      expect( elements ).any? do |e|
        e.children.any? {|c| c.name == 'textarea' && c.text == item[:about].to_s }
      end
    end
  end


  class SelectType < E
    include Rear
    model Book
    input :cover, :select do
      options('Solid', 'Soft')
    end
  end
  Spec.new SelectType do

    item, item_id = new_book( :cover => 'Soft')

    Testing :pane do
      get
      check( extract_elements ).any? {|e| e.text == 'Soft'}
    end

    Testing :editor do
      get :edit, item_id
      is(last_response).ok?
      check( extract_elements ).any? { |e|
        e.children.any? do |c|
          c.name == 'select' && c.attr(:name) == 'cover' && 
          c.children.any? {|cc| 
            cc.attr(:value) == 'Soft' && cc.attr(:selected)
          }
        end
      }
    end
  
  end


  class MultiSelectType < E
    include Rear
    model Book
    
    on_save do
      params['colors'] = params['colors'].join(',')
    end

    input :colors, :select, :multiple => true do
      options 'r' => 'Reg', 'g' => 'Green', 'b' => 'Blue' do
        item.colors.to_s.split(',')
      end
    end
  end
  Spec.new MultiSelectType do
    
    item, item_id = new_book( :colors => 'r,g')

    Testing :pane do

      get
      is(last_response).ok?
      check( extract_elements ).any? {|e| 
        e.text =~ /Red/ || e.text =~ /Green/
      }
    end

    Testing :editor do
      get :edit, item_id
      is(last_response).ok?
      check( extract_elements ).any? { |e|
        e.children.any? do |c|
          c.name == 'select' && c.attr(:name) == 'colors[]' &&
            c.children.any? {|cc| 
              cc.attr(:value) == 'r' && cc.attr(:selected)
            } && c.children.any? {|cc|
              cc.attr(:value) == 'g' && cc.attr(:selected)
            }
        end
      }
    end
  end


  class CheckboxType < E
    include Rear
    model Book
    
    on_save do
      params['colors'] = params['colors'].join(',')
    end

    input :colors, :checkbox do
      options 'r' => 'Reg', 'g' => 'Green', 'b' => 'Blue' do
        item.colors.to_s.split(',')
      end
    end
  end
  Spec.new CheckboxType do
    
    item, item_id = new_book( :colors => 'g,b')
    Testing :pane do
      get
      check( extract_elements ).any? {|e| 
        e.text =~ /Green/ || e.text =~ /Blue/
      }
    end

    Testing :editor do

      get :edit, item_id
      is(last_response).ok?
      elements = extract_elements('.editor-checkbox_container')
      item.colors.split(',').each do |color|
        check( elements ).any? { |e|
          e.children.any? { |c|
            c.name == 'input' && 
              c.attr(:type)  == 'checkbox' &&
              c.attr(:name)  == 'colors[]' &&
              c.attr(:value) == color && c.attr(:checked) 
          }
        }
      end
    end
  end


  class RadioType < E
    include Rear
    model Book
    input :cover, :radio do
      options('Solid', 'Soft') { item.cover }
    end
  end
  Spec.new RadioType do
    
    item, item_id = new_book( :cover => 'Solid')
    Testing :pane do
      get
      is(last_response).ok?
      check( extract_elements ).any? {|e| e.text == 'Solid' }
    end

    Testing :editor do
      get :edit, item_id
      is(last_response).ok?
      elements = extract_elements('.editor-radio_container')
      {'Solid' => true, 'Soft' => false}.each_pair do |value, status|
        check( elements ).any? { |e|
          e.children.any? do |c|
            c.name == 'input' && 
              c.attr(:type)  == 'radio' &&
              c.attr(:name)  == 'cover' &&
              c.attr(:value) == value   &&
              (status ? c.attr(:checked) : true)
          end
        }
      end
    end
  end


  class AttrsApp < E
    include Rear
    model Book
    input :name,  style: 'width: 100%;'
    input :about, cols: 10
  end
  Spec.new AttrsApp do
    
    item, item_id = new_book()

    get :edit, item_id
    is(last_response).ok?
    elements = extract_elements
    expect( elements ).any? { |e|
      e.children.any? {|c| 
        c.name == 'input' && c.attr(:style) == 'width: 100%;'
      }
    }
    expect( elements ).any? { |e|
      e.children.any? {|c| c.name == 'textarea' && c.attr(:cols) == '10' }
    }
  
  end

  class DisablerApp < E
    include Rear
    model Book

    input :name do
      pane false
    end

    input :about do
      editor false
    end
    
  end
  Spec.new DisablerApp do

    item, item_id = new_book()

    Testing :pane do
      get
      is(last_response).ok?
      elements = extract_elements
      Should 'show :about column' do
        expect( elements ).any? {|e| 
          e.children.any? {|c| c.to_s =~ /#{item[:about]}/}
        }
      end
      Should 'NOT show :name column' do
        refute do
          elements.any? do |e|
            e.children.any? {|c| c.text == item[:name]}
          end
        end == true
      end
    end

    Testing :editor do
      get :edit, item_id
      is(last_response).ok?
      elements = extract_elements
      Should 'show :name column' do
        expect( elements ).any? { |e| 
          e.children.any? do |c| 
            c.name == 'input' && c.attr(:value) == item[:name].to_s
          end
        }
      end
      Should 'NOT show :about column' do
        refute do
          elements.any? do |e|
            e.children.any? {|c| c.name == 'textarea'}
          end
        end == true
      end
    end
  end
end
