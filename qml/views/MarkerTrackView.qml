﻿import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1
import Littai 1.0

import '../shapes'
import '../common'

ColumnLayout {

    function send(address, marker) {
        window.osc.send(address, marker);
    }

    Storage {
        id: storage
        name: 'LITTAI'
        description: 'Interaction recognizer for LITTAI project.'
    }

    RowLayout {
        anchors.fill: parent

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumWidth: parent.width
        Layout.minimumHeight: parent.height - form.height - 5

        MarkerTracker {
            id: markerTracker
            property var currentMarkers : ({})

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumWidth: parent.width / 2
            Layout.maximumHeight: parent.height

            fps: 30
            predictionFrame: predictionFrameSlider.value
            inputImage: window.diffImage
            onInputImageChanged: update()
            contrastThreshold: contrastSlider.value
            contrastThresholdMin: contrastSliderMin.value
            contrastThresholdMax: contrastSliderMax.value
            contrastThresholdStep: contrastSliderStep.value
            onImageChanged: markerTrackerFpsCounter.update()
            onMarkersChanged: {
                for (var id in currentMarkers) {
                    currentMarkers[id].checked = false;
                }
                markers.forEach(function(marker) {
                    if (currentMarkers[marker.id]) {
                        results.updateMarker(marker);
                    } else {
                        results.createMarker(marker);
                    }
                    marker.checked = true;
                    currentMarkers[marker.id] = marker;
                });
                for (var id in currentMarkers) {
                    var marker = currentMarkers[id];
                    if (!marker.checked) {
                        results.removeMarker(marker);
                        delete currentMarkers[id];
                    }
                }
            }

            Fps {
                id: markerTrackerFpsCounter
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 5
            }
        }

        GroupBox {
            property var markers: ({})
            id: results
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumWidth: parent.width / 2
            Layout.maximumHeight: parent.height

            ScrollView {
                anchors.fill: parent

                ColumnLayout {
                    id: resultArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            function createMarker(marker) {
                send('/marker/update', marker);
                var markerDataQml = Qt.createComponent('MarkerData.qml');
                var markerData = markerDataQml.createObject(resultArea);
                markerData.Layout.minimumWidth = width - 20;
                markers[marker.id] = markerData;
                updateMarker(marker);
            }

            function updateMarker(marker) {
                send('/marker/update', marker);
                if (marker.id in markers) {
                    var markerData = markers[marker.id];
                    markerData.markerId = marker.id;
                    markerData.markerX = marker.x;
                    markerData.markerY = marker.y;
                    markerData.markerAngle = marker.angle * 180 / Math.PI;
                    markerData.markerSize = marker.size;
                    markerData.markerImage = marker.image;
                    markerData.markerPolygon = marker.polygon;
                    markerData.markerEdges = marker.edges;
                    markerData.markerIndices = marker.indices;
                    markerData.markerPatterns = marker.patterns;
                    markerData.frameCount = marker.frameCount;
                }
            }

            function removeMarker(marker) {
                send('/marker/remove', marker);
                if (marker.id in markers) {
                    markers[marker.id].destroy();
                    delete markers[marker.id];
                }
            }
        }
    }

    GroupBox {
        id: form
        anchors.bottom: parent.bottom
        Layout.fillWidth: true

        RowLayout {
            spacing: 30

            InputSlider {
                id: contrastSlider
                min: 0
                max: 150
                isInteger: true
                defaultValue: storage.get('markerTracker.contrastThreshold') || min
                onValueChanged: storage.set('markerTracker.contrastThreshold', value)
                label: 'Contrast Threshold'
            }

            InputSlider {
                id: contrastSliderMin
                min: 0
                max: 150
                isInteger: true
                defaultValue: storage.get('markerTracker.contrastThresholdMin') || 50
                onValueChanged: storage.set('markerTracker.contrastThresholdMin', value)
                label: 'ArUco Contrast Threshold Min'
            }

            InputSlider {
                id: contrastSliderMax
                min: 0
                max: 150
                isInteger: true
                defaultValue: storage.get('markerTracker.contrastThresholdMax') || 50
                onValueChanged: storage.set('markerTracker.contrastThresholdMax', value)
                label: 'ArUco Contrast Threshold Max'
            }

            InputSlider {
                id: contrastSliderStep
                min: 0
                max: 150
                isInteger: true
                defaultValue: storage.get('markerTracker.contrastThresholdStep') || 50
                onValueChanged: storage.set('markerTracker.contrastThresholdStep', value)
                label: 'ArUco Contrast Threshold Step'
            }

            InputSlider {
                id: predictionFrameSlider
                min: 0
                max: 15
                isInteger: true
                defaultValue: storage.get('markerTracker.predictionFrame') || min
                onValueChanged: storage.set('markerTracker.predictionFrame', value)
                label: 'Prediction Frame'
            }
        }
    }
}
