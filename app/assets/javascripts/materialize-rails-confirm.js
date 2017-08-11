$(function() {
  $.rails.allowAction = function(link) {
    if (!link.attr("data-confirm")) {
      return true;
    }

    $.rails.showConfirmDialog(link);
    return false;
  };

  $.rails.confirmed = function(link) {
    var temp = link.attr("data-confirm");
    link.removeAttr("data-confirm");
    link.trigger("click.rails");
    link.attr("data-confirm",temp);
    return
  };

  return $.rails.showConfirmDialog = function(link) {
    var message = link.attr("data-confirm");
    $.confirm({
      boxWidth: '80%',
      useBootstrap: false,
      theme: 'material',
      title: 'Confirm!',
      content: message,
      draggable: true,
      buttons: {
          confirm: {
          	btnClass: "btn-dark",
          	action: function () {
          		return $.rails.confirmed(link);
          	}
        	},
          cancel: {
          	action: function () {
              //Ignore
          	}
          }
      }
    });
  };
});