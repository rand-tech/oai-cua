const allResourceTypes = Object.values(chrome.declarativeNetRequest.ResourceType);


async function getPinnedTabId() {
    const result = await chrome.storage.session.get("pinnedTabId");
    return result["pinnedTabId"];
}

async function setPinnedTabId(value) {
    await chrome.storage.session.set({ ["pinnedTabId"]: value });
}

async function getActiveTabId() {
    const result = await chrome.storage.session.get("activeTabId");
    return result["activeTabId"];
}

async function setActiveTabId(value) {
    await chrome.storage.session.set({ ["activeTabId"]: value });
}

// This creates a pinned tab and moves it to the left-most
// position. Its presence ensures that Chrome cannot be quit
// by closing the last tab.
async function createPinnedTab() {
    chrome.tabs.create({ pinned: true, url: "http://localhost:31460/", active: false }, async function (tab) {
        await setPinnedTabId(tab.id);
    });
}

function getSanitizedUrl(urlString) {
    const url = new URL(urlString);
    url.search = '';
    return url.toString();
}

// The tab onRemoved listener does two main things:
// * If we're closing the pinned tab, recreate it
// * If the only tab left is the pinned tab, create a new regular tab
//
// This effectively ensures that a pinned tab and, at least, one
// regular tab are always open.
chrome.tabs.onRemoved.addListener(async function (tabId, removeInfo) {
    const pinnedTabId = await getPinnedTabId();
    if (tabId === pinnedTabId) {
        await createPinnedTab();
    }

    const allTabs = await chrome.tabs.query({});
    if (allTabs.length === 1) {
        // If the only tab we have left is the pinned tab, create
        // a new empty tab.
        chrome.tabs.create({});
    }
});

// The tab onActivated listener is responsible for preventing
// users from actually selecting the pinned tab.
// * If we don't know what the previous active tab is, i.e.
//   Chrome has just started up, set the previous active tab
//   to the tab that's not pinned.
// * If we are selecting a regular tab, set the previous active
//   tab to this tab.
// * If we are selecting the pinned tab, wait for a moment (to allow
//   this event handler to complete), then switch the tab to the
//   previous active tab.
chrome.tabs.onActivated.addListener(async function (activeInfo) {
    const pinnedTabId = await getPinnedTabId();
    let activeTabId = await getActiveTabId();

    if (!activeTabId) {
        chrome.tabs.query({}, async function (tabs) {
            for (let tab of tabs) {
                if (tab.id !== pinnedTabId) {
                    activeTabId = tab.id;
                    break;
                }
            }
        });
    }

    if (activeInfo.tabId === pinnedTabId) {
        setTimeout(() => {
            chrome.tabs.update(activeTabId, { active: true });
        }, 100);
    } else {
        await setActiveTabId(activeInfo.tabId);
    }

    const tab = await chrome.tabs.get(activeInfo.tabId);
    if (tab.url) {
      sendConfig(getSanitizedUrl(tab.url));
    }
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
    if (changeInfo.url) {
      sendConfig(getSanitizedUrl(changeInfo.url));
    }
});

async function getConfig() {
    try {
        const response = await fetch('http://localhost:8080/config');
        const data = await response.json();

        if (data.xff_ip) {
            updateRequestRules(data.xff_ip);
        }
    } catch (error) {
        console.error('Error getting config from localhost:', error);
    }
}

async function sendConfig(url) {
    try {
        const response = await fetch("http://localhost:8080/config", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({ url }),
        });
    } catch (error) {
        console.error('Error sending config to localhost:', error);
    }
}

function updateRequestRules(ipAddress) {
    const ruleId = 1;

    chrome.declarativeNetRequest.updateDynamicRules({
        removeRuleIds: [ruleId],
        addRules: [
            {
                id: ruleId,
                priority: 1,
                action: {
                    type: "modifyHeaders",
                    requestHeaders: [
                        {
                            header: "X-Forwarded-For",
                            operation: "set",
                            value: ipAddress
                        }
                    ]
                },
                condition: {
                    urlFilter: "*",
                    resourceTypes: allResourceTypes,
                }
            }
        ]
    });
}

getConfig();
setInterval(getConfig, 5 * 1000);

(async () => {
    const pinnedTabId = await getPinnedTabId();
    if (!pinnedTabId) {
        const tabs = await chrome.tabs.query({ pinned: true, url: "http://localhost:31460/*" });
        if (tabs.length > 0) {
            await setPinnedTabId(tabs[0].id);
        } else {
            createPinnedTab();
        }
    }
})();

chrome.history.onVisited.addListener((historyEntry) => {
    fetch("http://localhost:8080/events", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            event_type: "navigated",
            event_data: {
                url: historyEntry.url,
            },
        })
    });
});

chrome.runtime.onMessage.addListener((request, sender) => {
    if (request.type === "event") {
        fetch("http://localhost:8080/events", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                event_type: request.event_type,
                event_data: request.event_data,
            })
        });
    }
});
