$(function () {
    $("#container").hide();
    window.addEventListener('message', function(event) {
        if (event.data.action === "open") {
            $("#container").show();
        } else if (event.data.action === "close") {
            $("#container").hide();
        }
    });

    document.onkeyup = function (data) { // pess esc to close
        if (data.which == 27) {
            $.post('https://foltone_ped_meca/exit', JSON.stringify({}));
            return
        }
    };
})

function buttonselect(data) {
    $.post(`https://foltone_ped_meca/action`, JSON.stringify(data));
}
