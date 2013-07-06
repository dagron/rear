$(function(){
  $('#fileupload').fileupload({
    fail: function(e, data) {
      var failed_uploads = [];
      $.each(data.files, function(i,f) {
        failed_uploads.push('"' + f.name + '" - ' + data.errorThrown);
      });
      Rear.sticky_warn(failed_uploads.join("\n"));
    },
    start: function() {
      $('#progress_modal').modal({keyboard: false, backdrop: 'static'});
    },
    stop: function() {
      var fuel = this;
      window.setTimeout(function() {
        $('#progress_modal').modal('hide');
        if(typeof fileupload_callback === 'function')
          fileupload_callback();
        else window.location.reload(true);
      }, 600);
    },
    progressall: function (e, data) {
      var progress = parseInt(data.loaded / data.total * 100, 10);
      $('#progress_bar .bar').css('width', progress + '%');
    }
  });
});
