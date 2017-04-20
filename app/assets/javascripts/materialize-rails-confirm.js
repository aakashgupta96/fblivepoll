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
    $("#glass1").remove();
    $("#modal1000").remove()
    link.trigger("click.rails");
    link.attr("data-confirm",temp);
    return
  };

  return $.rails.showConfirmDialog = function(link) {
    var html, message;
    html = void 0;
    glass = "<div id=\"glass1\" style=\" position:absolute; opacity: 0.5; background: black; width: 100%; height: 5000px; z-index: 100000000;\"></div>";
    message = void 0;
    message = link.attr("data-confirm");
    html = "<div id=\"modal1000\" class=\"modal\" style=\"z-index: 100000003; display: block; opacity: 1; color: grey; transform: scaleX(1); top: 10%;\"> <div class=\"modal-content\"><h5>" + message + "</h5></div><div class=\"modal-footer\"><a class=\"modal-action modal-close waves-effect waves-red btn-flat close\">Cancel</a><a class=\"modal-action modal-close waves-effect waves-green btn-flat confirm\">OK</a></div></div>";
    $("body").append(glass);
    $("body").append(html);

    $("#modal1000").modal({
      complete: function() {
        $("#glass1").remove();
        return $("#modal1000").remove();
      }
    });

    $("#modal1000 .close").on("click", function() {
      $("#glass1").remove();
      return $("#modal1000").remove();;
    });

    return $("#modal1000 .confirm").on("click", function() {
      return $.rails.confirmed(link);
    });
  };
});