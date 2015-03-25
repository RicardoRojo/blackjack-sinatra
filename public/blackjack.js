$(document).ready(function(){
  hit_form();
  stay_form();
  dealer_hit();
});

function hit_form(){
  $(document).on('click','#hit_form input', function(){

    $.ajax({
      url: '/player/hit',
      type: 'POST'
    }).done(function(msg){
      $('.maindiv').replaceWith(msg);
    });
    return false;
  });
}
function stay_form(){
  $(document).on('click','#stay_form input', function(){

    $.ajax({
      url: "/player/stay",
      type: "POST"
    }).done(function(msg){
      $('.maindiv').replaceWith(msg);
    });
    return false;
  });
}
function dealer_hit(){
  $(document).on('click','#dealer_hit input', function(){
    $.ajax({
      url: "/dealer/hit",
      type: "POST"
    }).done(function(msg){
      $('.maindiv').replaceWith(msg);
    });
    return false;
  });
}