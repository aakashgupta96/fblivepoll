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
    var width = Math.min(650,0.9*$(window).width());
    var message = link.attr("data-confirm");
    $.confirm({
      boxWidth: width + "px",
      useBootstrap: false,
      theme: 'material',
      title: 'Confirm!',
      content: message,
      draggable: true,
      buttons: {
          confirm: {
          	btnClass: "btn-dark",
          	action: function () {
              this.$body.hide();
          		return $.rails.confirmed(link);
          	}
        	},
          cancel: {
          	action: function () {
              this.$body.hide();
          	}
          }
      }
    });
  };
});