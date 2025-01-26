async function sha1(text) {
  const encoder = new TextEncoder();
  const hash = await window.crypto.subtle.digest("SHA-1", encoder.encode(text));
  return Array.from(new Uint8Array(hash))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

document.addEventListener("copy", async () => {
  const text = document.getSelection().toString();
  if (text) {
    chrome.runtime.sendMessage({
      type: "event",
      event_type: "copy",
      event_data: {
        content: text,
        content_length: text.length,
        content_sha1: await sha1(text),
        url: window.location.href,
      },
    });
  }
});

document.addEventListener("paste", async () => {
  try {
    const text = await navigator.clipboard.readText();
    chrome.runtime.sendMessage({
      type: "event",
      event_type: "paste",
      event_data: {
        content: text,
        content_length: text.length,
        content_sha1: await sha1(text),
        url: window.location.href,
      },
    });
  } catch (error) {
    console.error("Failed to read clipboard contents:", error);
  }
});

document.addEventListener("change", (event) => {
  const target = event.target;
  if (target.tagName === "INPUT" && target.type === "file") {
    chrome.runtime.sendMessage({
      type: "event",
      event_type: "upload",
      event_data: {
        files: target.files,
        file: target.value,
        url: window.location.href,
      },
    });
  }
});

document.addEventListener("drop", (event) => {
  if (event.dataTransfer && event.dataTransfer.files.length > 0) {
    const files = event.dataTransfer ? event.dataTransfer.files : event.target.files;
    chrome.runtime.sendMessage({
      type: "event",
      event_type: "upload",
      event_data: {
        files: files,
        url: window.location.href,
      },
    });
  }
});
