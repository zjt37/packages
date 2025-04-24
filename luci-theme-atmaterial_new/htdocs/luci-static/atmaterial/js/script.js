
// JavaScript template rendering example for OpenWRT 24.10

// Function to render a template with dynamic data
function renderTemplate(templateId, data) {
    var template = document.getElementById(templateId).innerHTML;
    for (var key in data) {
        var regex = new RegExp("{{" + key + "}}", "g");
        template = template.replace(regex, data[key]);
    }
    return template;
}

// Example usage:
document.addEventListener("DOMContentLoaded", function() {
    var data = {
        title: "Welcome to Atmaterial",
        description: "This description is rendered dynamically using JavaScript templates."
    };
    document.getElementById("dynamic-content").innerHTML = renderTemplate("template", data);
});
