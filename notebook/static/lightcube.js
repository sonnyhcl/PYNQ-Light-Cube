/**
 * Created by sonny on 2017/7/23.
 */

var graph = 'myDiv';

var myPlot = document.getElementById(graph);

var layout = {
    scene: {
        camera: {
            eye: {
                x: 1.5,
                y: -1.5,
                z: 1.5
            }
        }
    },
    showlegend: false,
    autosize: false,
    width: 1000,
    height: 1080
};

var config = {
    displayModeBar: false
};

var cube = [
    {
        x: [],
        y: [],
        z: [],
        name: 'on',
        mode: 'markers',
        marker: {
            size: 30,
            line: {
                color: 'rgba(217, 217, 217, 0.14)',
                width: 0.5
            },
            opacity: 1
        },
        type: 'scatter3d'
    },
    {
        x: [],
        y: [],
        z: [],
        name: 'off',
        mode: 'markers',
        marker: {
            color: 'rgba(127, 127, 127, 0.8)',
            size: 20,
            symbol: 'circle',
            line: {
                color: 'rgb(204, 204, 204)',
                width: 1
            },
            opacity: 1
        },
        type: 'scatter3d'
    }
];

var socket = io.connect('http://' + document.domain + ':' + location.port);

socket.on('connect', function () {
    console.log("socketio server connected");
});

socket.on('run', function (ret) {
    redraw(ret);
});

$(document).ready(function () {
    console.log('document ready');
    Plotly.newPlot(graph, cube, layout, config);
    myPlot.on('plotly_click', plotly_click_cb);
    refresh_frame();
});

var evTimeStamp = 0;

function plotly_click_cb(data) {
    var nowTimeStamp = new Date();
    if (nowTimeStamp - evTimeStamp < 300) {
        console.log("click callback twice");
        return;
    }
    evTimeStamp = nowTimeStamp;

    x_pos = data.points[0].x;
    y_pos = data.points[0].y;
    z_pos = data.points[0].z;
    console.log(x_pos, y_pos, z_pos);

    $.post('toggle', {
            'x': x_pos,
            'y': y_pos,
            'z': z_pos
        }, function (ret) {
            refresh_frame();
        }, 'json'
    )
}

function refresh_frame() {
    $.post("get_xyz",
        function (ret) {
            redraw(ret);
        }, 'json'
    );
}

function redraw(ret) {
    cube[0]['x'] = ret.x1;
    cube[0]['y'] = ret.y1;
    cube[0]['z'] = ret.z1;
    cube[1]['x'] = ret.x2;
    cube[1]['y'] = ret.y2;
    cube[1]['z'] = ret.z2;
    Plotly.redraw(graph);
}

function animation(mode) {
    console.log('animation ' + mode);
    $("button").attr("disabled", "disabled");
    $.post("animation", {
            'mode': mode
        }, function (ret) {
            $("button").removeAttr("disabled");
            console.log(ret);
        }, 'json'
    );
}
           