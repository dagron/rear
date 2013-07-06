RearAPI = function() {

  var errorInstance;

  this.switch_page = function(domSelector, url) {
    $.ajax({
      url:  url,
      type: 'GET'
    }).done(function(response) {
      $(domSelector).html(response);
    });
  }

  this.check_multiple = function(domSelector, sourceElement, isControlElement) {
    var status = sourceElement.checked;

    if(isControlElement)
      return $(domSelector).prop('checked', status);
    
    if (event.shiftKey) { // if holding Shift, toggle elements before clicked one
      $(domSelector).each(function(i,e) {
        // break iteration when arriving at checked element
        if(e == sourceElement) return false;
        $(e).prop('checked', status);
      });
    } else if (event.altKey) { // if holding Alt, toggle elements after clicked one
      var sourceElementFound = false;
      $(domSelector).each(function(i,e) {
        // moving to next element until arriving to checked one
        if(e == sourceElement) return sourceElementFound = true;
        if(sourceElementFound) $(e).prop('checked', status);
      });
    }
  }

  this.trigger_selectable = function(domSelector) {
    // using select.selectable instead of just .selectable
    // to avoid Select2 to apply twice when pages loaded by XHR.
    // that's it, Select2 converts .selectable elements into divs,
    // so select.selectable wont match converted elements anymore.
    $(domSelector || 'select.selectable').each(function(i,e) {
      if($(e).select2 == 'undefined') return false;
      $(e).select2({width: 'resolve'});
    });
  }

  this.trigger_hoverable = function(domSelector) {
    $(domSelector || ".hoverable").hover(
      function () { $(this).addClass("hoverable-hover") },
      function () { $(this).removeClass("hoverable-hover") }
    );
  }

  this.CRUD = function(objectID, baseURL, redirectURL, readonly) {
    var objectID = objectID,
      baseURL = baseURL,
      redirectURL = redirectURL;

    this.save = function() {
      if(readonly) {
        Rear.warn('ReadOnly Mode! Item Not Saved');
        return false;
      }
      if (objectID > 0) {
        var requestMethod = 'PUT',
          url   = [baseURL, objectID].join('/'),
          alert = "Item Successfully Updated";
      } else {
        var requestMethod = 'POST',
          url   = baseURL,
          alert = "Item Successfully Created";
      }

      $.ajax({
        url:  url,
        type: requestMethod,
        data: $('#editor-main_form').serialize(),
        complete: function(xhr) {
          if(xhr.statusText == "OK") {
            if (objectID > 0) {
              if(errorInstance) errorInstance.close();
              Rear.alert(alert);
            } else {
              localStorage['flash'] = alert;
              window.location = [redirectURL, xhr.responseText].join('/');
            }
          } else Rear.error(xhr.responseText);
        }
      });
    }

    this.delete = function(redirectURL) {
      if(readonly) {
        Rear.warn('ReadOnly Mode! Item Not Deleted');
        return false;
      }
      $.ajax({
        url:  [baseURL, objectID].join('/'),
        type: 'DELETE',
        complete: function(xhr) {
          if(xhr.statusText == "OK") {
            localStorage['flash'] = "Item Successfully Deleted";
            window.location = redirectURL;
          } else Rear.error(xhr.responseText);
        }
      });
    }

    this.delete_selected = function(baseURL, redirectURL, readonly) {
      if(readonly) {
        Rear.warn('ReadOnly Mode! No Items Deleted');
        return false;
      }
      var items = []
      $('.pane-selected_item:checked').each(function(i,e) {
        items.push($(e).val());
      });
      $.ajax({
        url:  baseURL,
        type: 'DELETE',
        data: {items: items.join(' ')},
        complete: function(xhr) {
          if(xhr.statusText == "OK") {
            localStorage['flash'] = "Selected Items Successfully Deleted";
            window.location = redirectURL;
          } else Rear.error(xhr.responseText);
        }
      });
    }
  }

  this.BulkCRUD = function(baseURL) {

    this.invoke = function(){
      var form  = $('#bulk_editor-main_form');
      if(!form) {
        Rear.error('No form found for bulk editing');
        return false;
      }
      
      $.ajax({
        url:  baseURL,
        type: 'POST',
        data: form.serialize(),
        complete: function(xhr) {
          if(xhr.statusText == 'OK') {
            if(errorInstance) errorInstance.close();
            Rear.sticky_alert(xhr.responseText);
          } else
            Rear.error(xhr.responseText);
        }
      });
    }
  }

  this.Assoc = function(baseURL, domSelector, readonly) {
    var urlArray = baseURL.split('?');
    var     baseURL = urlArray[0],
        queryString = urlArray[1],
        domSelector = domSelector,
           readonly = readonly;

    this.load = function() {
      this.load_attached();
      this.load_detached();
    }
    this.load_attached = function(attacher) {
      // queryString are used here only to pass assoc filters
      // and it makes sense to apply assoc filters only on detached items
      $.get(baseURL + '/true', function(response) {
        $(domSelector.replace(/_detached$/, '')).html(response);
        $('.pane-assoc-attacher').each(function(i,e) {
          $(e).attr('checked', e == attacher);
        });
      });
    }
    this.load_detached = function(callback) {
      $.get(baseURL, queryString, function(response) {
        $(domSelector + '_detached').html(response);
        callback && typeof(callback) === "function" && callback();
      });
    }

    this.create = function(remoteID) {
      if(readonly) {
        Rear.warn('ReadOnly Relation! Any updates discarded');
        return false;
      }
      invoke('POST', remoteID);
    }
    this.delete = function(remoteID) {
      if(readonly) {
        Rear.warn('ReadOnly Relation! Any updates discarded');
        return false;
      }
      invoke('DELETE', remoteID);
    }

    var invoke = function(requestMethod, remoteID) {
      $.ajax({
        type: requestMethod,
        url:  baseURL,
        data: {target_item_id: remoteID},
        complete: function(xhr, txtResponse) {
          if(txtResponse == 'success') {
            Rear.alert('Relation Updated');
          } else {
            if(xhr.status == 400)
              Rear.warn(xhr.responseText);
            else if(xhr.status == 500)
              Rear.error(xhr.responseText);
          }
        }
      });
    }

  }

  this.Filters = function(domID, url) {
    var domID = domID, url = url;

    this.apply = function() {
      invoke(
        '#' + domID,
        $('#pane-filters-form-' + domID).serialize()
      );
    }

    this.reset = function() {
      invoke('#' + domID, {});
    }

    this.update = function() {
      invoke(
        '#pane-filters-input-' + domID,
        $('#pane-filters-form-' + domID).serialize()
      );
    }

    var invoke = function(domSelector, data) {
      $.ajax({
        url:  url, type: 'GET', data: data
      }).done(function(response) {
        $(domSelector).html(response);
      });
    }
  }

  this.openFileBrowser = function(url) {
    var width  = 800,
        height = 600,
        left   = (screen.width/2)-(width/2),
        top    = (screen.height/2)-(height/2);
    window.open(
      url,
      '_blank',
      'menubar=0,toolbar=0' +
      ',width='  + width    +
      ',height=' + height   +
      ',top='    + top      +
      ',left='   + left
    );
  }

  this.updateImageColumn = function(columnID, value) {
    var input = $('#inputFor' + columnID)
    input.val(value);
    
    if(value) {
      $('#imageFor' + columnID).attr('src', value);
      $('#containerFor' + columnID).show();
      $('#resetButtonFor' + columnID).show();
    } else {
      $('#containerFor' + columnID).hide();
      $('#resetButtonFor' + columnID).hide();
    }

    var crudURL = input.attr('data-url'),
        name = input.attr('name'),
        item = input.attr('data-id'),
        data = {};

    if (crudURL && name && item) {
      data[name] = value;

      $.ajax({
        type: 'PUT',
        url:  [crudURL, item].join('/'),
        data: data,
        complete: function(xhr, txtResponse) {
          if(txtResponse == 'success')
            Rear.alert(name + ' updated');
          else
            Rear.error(xhr.responseText);
        }
      });

    }
  }

  this.resetImageColumn = function(columnID) {
    if (confirm("This will reset current image. Continue?"))
      Rear.updateImageColumn(columnID, null);
  }

  this.alert = function(msg, timeout) {
    noty({
      text:    msg,
      type:    'information',
      layout:  'topRight',
      timeout: timeout || 2000
    });
  }

  this.sticky_alert = function(msg) {
    noty({
      text:    msg,
      type:    'information',
      layout:  'topRight'
    });
  }

  this.warn = function(msg, timeout) {
    noty({
      text:    msg,
      type:    'warning',
      layout:  'topRight',
      timeout: timeout || 3000
    });
  }

  this.sticky_warn = function(msg) {
    noty({
      text:    msg,
      type:    'warning',
      layout:  'topRight'
    });
  }

  this.error = function(msg) {
    msg = msg.replace(/</gm, '&lt;').replace(/>/gm, '&gt;').
      replace(/\n|\r/gm, '<br>').replace(/\t/gm, '&nbsp;&nbsp;');
    errorInstance = noty({
      text: '<div style="text-align: left; max-height: 280px; overflow: auto;">' + msg + '</div>',
      type: 'warning', layout:  'top', modal:   true, closeWith: ['button'],
      buttons: [
        {addClass: 'btn btn-primary', text: 'Close', onClick: function($noty) {
            $noty.close();
          }
        }
      ]
    });
  }

}

Rear = new RearAPI();

$(function(){
  if(localStorage['flash']) {
    Rear.alert(localStorage['flash']);
    localStorage.removeItem('flash');
  }
});
