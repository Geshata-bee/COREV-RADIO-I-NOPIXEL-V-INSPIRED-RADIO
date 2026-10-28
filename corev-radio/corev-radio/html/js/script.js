const resourceName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "corev-radio";

const radioState = {
    powered: true,
    onRadio: false,
    channel: 0,
    volume: 50,
    muted: false,
    loudSpeaker: false
};

const talkSound = {
    src: "sounds/radio_interact.ogg"
};

function playTalkSound(volume) {
    try {
        const audio = new Audio(talkSound.src);
        audio.volume = Math.min(Math.max(Number(volume) || 0, 0), 1);
        const result = audio.play();

        if (result && typeof result.catch === "function") {
            result.catch(function() {});
        }
    } catch (e) {}
}

const CorevRadio = {};

function nuiPost(callback, data = {}) {
    $.post(`https://${resourceName}/${callback}`, JSON.stringify(data));
}

function channelPayload() {
    return {
        channel: $("#channel").val()
    };
}

function formatChannel(channel) {
    const value = Number(channel);

    if (!Number.isFinite(value) || value <= 0) {
        return "";
    }

    return Number.isInteger(value) ? value.toFixed(1) : value.toString();
}

function syncRadioState(data = {}) {
    Object.assign(radioState, data);

    const channelInput = $("#channel");
    const channelElement = channelInput.get(0);
    const displayChannel = formatChannel(radioState.channel);

    $(".radio-container")
        .toggleClass("is-off", !radioState.powered)
        .toggleClass("is-on-channel", radioState.onRadio)
        .toggleClass("is-muted", radioState.muted)
        .toggleClass("is-loudspeaker", radioState.loudSpeaker);

    $("#poweredOff").text(radioState.powered ? "ON" : "OFF");
    channelInput.attr("placeholder", radioState.powered ? "0.0" : "OFF");

    if (document.activeElement !== channelElement) {
        channelInput.val(displayChannel);
    }
}

function sanitizeChannelInput() {
    const input = $("#channel");
    let value = input.val().replace(",", ".").replace(/[^0-9.]/g, "");
    const firstDot = value.indexOf(".");

    if (firstDot !== -1) {
        value = value.slice(0, firstDot + 1) + value.slice(firstDot + 1).replace(/\./g, "");
    }

    input.val(value.slice(0, 6));
}

function togglePower() {
    nuiPost("poweredOff", channelPayload());
}

function toggleLoudspeaker() {
    nuiPost("toggleLoudspeaker");
}

CorevRadio.SlideUp = function() {
    $(".container").css("display", "block");
    $(".radio-container")
        .stop(true, true)
        .css({ bottom: "-520px", opacity: 0 })
        .animate({ bottom: "0px", opacity: 1 }, 250);
};

CorevRadio.SlideDown = function() {
    $(".radio-container")
        .stop(true, true)
        .animate({ bottom: "-520px", opacity: 0 }, 420, function() {
            $(".container").css("display", "none");
        });
};

$(function() {
    window.addEventListener("message", function(event) {
        const data = event.data || {};

        if (data.type === "open") {
            if (data.version) {
                $("#version, .version-text").text(data.version);
            }

            syncRadioState(data);
            CorevRadio.SlideUp();
        }

        if (data.type === "playSound") {
            playTalkSound(data.volume);
        }

        if (data.type === "close") {
            CorevRadio.SlideDown();
        }

        if (data.type === "radioState") {
            syncRadioState(data);
        }
    });

    $("#channel").on("input", sanitizeChannelInput);

    document.onkeyup = function(data) {
        if (data.key === "Escape") {
            nuiPost("escape");
        } else if (data.key === "Enter") {
            nuiPost("joinRadio", channelPayload());
        } else if (data.key.toLowerCase() === "e") {
            togglePower();
        } else if (data.key.toLowerCase() === "l") {
            toggleLoudspeaker();
        }
    };

    syncRadioState(radioState);
});

$(document).on("click", "#submit", function(e) {
    e.preventDefault();
    nuiPost("joinRadio", channelPayload());
});

$(document).on("click", "#muteRadio", function(e) {
    e.preventDefault();
    nuiPost("muteRadio");
});

$(document).on("click", "#poweredOff, #powerPrompt", function(e) {
    e.preventDefault();
    togglePower();
});

$(document).on("click", "#loudSpeaker", function(e) {
    e.preventDefault();
    toggleLoudspeaker();
});
