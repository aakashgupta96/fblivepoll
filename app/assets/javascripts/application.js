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
// = require materialize-rails-confirm.js
// = require_tree

var width;
$( document ).ready(function(){
    width = Math.min(650,0.9*$(window).width());
    $('.modal').modal();
    $('.parallax').parallax();
    $('.carousel.carousel-slider').carousel({fullWidth: true});
    $(".button-collapse").sideNav();
    $('#faqs-section ul.tabs').tabs({
        swipeable: true
    });
    $('.collapsible').collapsible('open',0);
    $('.dropdown-button').dropdown({
      inDuration: 700,
      outDuration: 700,
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

    $('#question-form').on('submit',function(){
      return validatePhoneNumber($("#icon_telephone").val()) && validateEmailId($("#icon_email").val());
    });

})

$(window).load(function(){
    //$("#cover").fadeOut(200);
});

function validateAudioFiles(inputFile) {
    var extName;
    var maxFileSize = $(inputFile).data('max-file-size');
    var sizeExceeded = false;
    var extError = false;

    var maxExceededMessage = "This file exceeds the maximum allowed file size " + parseInt(maxFileSize/(1024*1024)) + "MB.";
    var extErrorMessage = "Only audio file with extension: .mp3 or .aac is allowed";
    var allowedExtension = ["mp3","aac"];
    
    $.each(inputFile.files, function() {
        if (this.size && maxFileSize && this.size > parseInt(maxFileSize)) {sizeExceeded=true;};
        extName = this.name.split('.').pop();
        if ($.inArray(extName, allowedExtension) == -1) {extError=true;};
    });
    if (sizeExceeded) {
        Materialize.toast(maxExceededMessage, 5000);
        $(inputFile).val('');
    };

    if (extError) {
        Materialize.toast(extErrorMessage, 5000);
        $(inputFile).val('');
    };
}

function validateVideoFiles(inputFile) {
    var extName;
    var maxFileSize = $(inputFile).data('max-file-size');
    var sizeExceeded = false;
    var extError = false;

    var maxExceededMessage = "This file exceeds the maximum allowed file size " + parseInt(maxFileSize/(1024*1024)) + "MB.";
    var extErrorMessage = "Only video file with extension: .mp4, .m4v, .ogg, .ogv or .mpeg is allowed";
    var allowedExtension = ["mp4", "m4v", "ogg", "ogv", "mpeg"];

    $.each(inputFile.files, function() {
        if (this.size && maxFileSize && this.size > parseInt(maxFileSize)) {sizeExceeded=true;};
        extName = this.name.split('.').pop();
        if ($.inArray(extName, allowedExtension) == -1) {extError=true;};
    });
    if (sizeExceeded) {
        Materialize.toast(maxExceededMessage, 5000);
        $(inputFile).val('');
    };

    if (extError) {
        Materialize.toast(extErrorMessage, 5000);
        $(inputFile).val('');
    };
}


function validateImageFiles(inputFile) {
    var extName;
    var maxFileSize = $(inputFile).data('max-file-size');
    var sizeExceeded = false;
    var extError = false;

    var maxExceededMessage = "This file exceeds the maximum allowed file size " + parseInt(maxFileSize/(1024*1024)) + "MB.";
    var extErrorMessage = "Only image file with extension: .jpg, .jpeg, .gif or .png is allowed";
    var allowedExtension = ["jpg", "jpeg", "gif", "png"];


    $.each(inputFile.files, function() {
        if (this.size && maxFileSize && this.size > parseInt(maxFileSize)) {sizeExceeded=true;};
        extName = this.name.split('.').pop();
        if ($.inArray(extName, allowedExtension) == -1) {extError=true;};
    });
    if (sizeExceeded) {
        Materialize.toast(maxExceededMessage, 5000);
        $(inputFile).val('');
    };

    if (extError) {
        Materialize.toast(extErrorMessage, 5000);
        $(inputFile).val('');
    };
};

function validatePhoneNumber(phoneNumber) {
  var pattern1 = /^\d{10}$/;
  var pattern2 = /^([+])\(?([0-9]{2})\)?[- ]?([0-9]{10})$/;
  if(phoneNumber.match(pattern1) || phoneNumber.match(pattern2))
  {  
    return true;  
  }  
  else  
  {  
    $.alert({
      theme: "supervan",
      useBootstrap: false,
      title: "Invalid Details!",
      content: "Phone Number entered is incorrect !!!"
    })
    return false;  
  }  
}

function validateEmailId(emailId){
  var pattern = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
  if(emailId.match(pattern))
  {  
    return true;  
  }  
  else  
  {  
    $.alert({
      theme: "supervan",
      useBootstrap: false,
      title: "Invalid Details!",
      content: "Email ID entered is incorrect !!!"
    })
    return false;  
  }
}