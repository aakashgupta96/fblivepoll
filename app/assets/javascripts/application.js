// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
// require turbolinks

// = require jquery
// = require jquery_ujs
// = require materialize
//= require materialize-rails-confirm.js
// = require_tree


$(function(){ $('.carousel.carousel-slider').carousel({full_width: true}); });
$( document ).ready(function(){
    $('.parallax').parallax();
    $('.carousel.carousel-slider').carousel({fullWidth: true});
    $('.scrollspy').scrollSpy();
    $(".button-collapse").sideNav();
    $('.dropdown-button').dropdown({
      inDuration: 400,
      outDuration: 600,
      constrain_width: true, // Does not change width of dropdown to that of the activator
      hover: true, // Activate on hover
      gutter: 0, // Spacing from edge
      belowOrigin: true, // Displays dropdown below the button
      alignment: 'left' // Displays dropdown with edge aligned to the left of button
    });
    $("#nextCarousel").click(function(){
        $('.carousel').carousel('next');
    });

    $("#prevCarousel").click(function(){
        $('.carousel').carousel('prev');
    });

    window.fbAsyncInit = function() {
      FB._https = true;
      FB.init({
        appId      : '241493676272963',
        xfbml      : true,
        version    : 'v2.8'
      });
    };

    (function(d, s, id){
      var js, fjs = d.getElementsByTagName(s)[0];
      if (d.getElementById(id)) {return;}
      js = d.createElement(s); js.id = id;
      js.src = "https://connect.facebook.net/en_US/all.js";
      fjs.parentNode.insertBefore(js, fjs);
    }(document, 'script', 'facebook-jssdk'));


  })

  $(window).load(function(){
    $("#cover").fadeOut(200);
    //$('.carousel.carousel-slider').height($(".plugin")[0].getBoundingClientRect().height + 90);
});
  $(window).resize(function(){
    //$('.carousel.carousel-slider').height($(".plugin")[0].getBoundingClientRect().height + 90);
  });
function validateAudioFiles(inputFile) {
    var maxExceededMessage = "This file exceeds the maximum allowed file size (50 MB)";
    var extErrorMessage = "Only audio file with extension: .mp3, .m4a, .mp4a, .wma, .wav or .aac is allowed";
    var allowedExtension = ["mp3", "m4a", "mp4a", "aac", "wma", "wav"];

    var extName;
    var maxFileSize = $(inputFile).data('max-file-size');
    var sizeExceeded = false;
    var extError = false;

    $.each(inputFile.files, function() {
        if (this.size && maxFileSize && this.size > parseInt(maxFileSize)) {sizeExceeded=true;};
        extName = this.name.split('.').pop();
        if ($.inArray(extName, allowedExtension) == -1) {extError=true;};
    });
    if (sizeExceeded) {
        window.alert(maxExceededMessage);
        $(inputFile).val('');
    };

    if (extError) {
        window.alert(extErrorMessage);
        $(inputFile).val('');
    };
}

function validateVideoFiles(inputFile) {
    var maxExceededMessage = "This file exceeds the maximum allowed file size (500 MB)";
    var extErrorMessage = "Only audio file with extension: .mpeg, .mp4, .flv, .mkv or .wmv is allowed";
    var allowedExtension = ["mp4", "mpeg", "avi", "flv", "mkv", "wmv"];

    var extName;
    var maxFileSize = $(inputFile).data('max-file-size');
    var sizeExceeded = false;
    var extError = false;

    $.each(inputFile.files, function() {
        if (this.size && maxFileSize && this.size > parseInt(maxFileSize)) {sizeExceeded=true;};
        extName = this.name.split('.').pop();
        if ($.inArray(extName, allowedExtension) == -1) {extError=true;};
    });
    if (sizeExceeded) {
        window.alert(maxExceededMessage);
        $(inputFile).val('');
    };

    if (extError) {
        window.alert(extErrorMessage);
        $(inputFile).val('');
    };
}


function validateImageFiles(inputFile) {
    var maxExceededMessage = "This file exceeds the maximum allowed file size (5 MB)";
    var extErrorMessage = "Only image file with extension: .jpg, .jpeg, .gif or .png is allowed";
    var allowedExtension = ["jpg", "jpeg", "gif", "png"];

    var extName;
    var maxFileSize = $(inputFile).data('max-file-size');
    var sizeExceeded = false;
    var extError = false;

    $.each(inputFile.files, function() {
        if (this.size && maxFileSize && this.size > parseInt(maxFileSize)) {sizeExceeded=true;};
        extName = this.name.split('.').pop();
        if ($.inArray(extName, allowedExtension) == -1) {extError=true;};
    });
    if (sizeExceeded) {
        window.alert(maxExceededMessage);
        $(inputFile).val('');
    };

    if (extError) {
        window.alert(extErrorMessage);
        $(inputFile).val('');
    };
};

function validateReactions(x) {
    console.log($('#'+x.id).val());
    
};