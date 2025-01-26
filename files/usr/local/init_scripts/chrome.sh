#!/bin/bash

set -xe

# If NEBULA_NAMESERVER is set, it means we want to spin up a VM that explicitly
# configures a DNS server to use (presumably one that blocks specific sites).
if [ -n "${NEBULA_NAMESERVER}" ]; then
    echo "nameserver ${NEBULA_NAMESERVER}" > /etc/resolv.conf
fi

if [ -z "$CDP_PORT" ]; then
    echo "missing CDP_PORT env var"
    exit 1
fi
if [ -z "$DISPLAY" ]; then
    echo "missing DISPLAY env var"
    exit 1
fi
if [ -z "$DISPLAY_SCALE_FACTOR" ]; then
    echo "missing DISPLAY_SCALE_FACTOR env var"
    exit 1
fi
if [ -z "$DISPLAY_SIZE" ]; then
    echo "missing DISPLAY_SIZE env var"
    exit 1
fi
if [ -z "$TARGET" ]; then
    echo "missing TARGET env var"
    exit 1
fi
if [ -z "$CHROMIUM_VERSION" ]; then
    echo "missing CHROMIUM_VERSION env var"
    exit 1
fi

user_data_dir="/home/oai/.chromium"

if [ ! -d "$user_data_dir" ]; then
    su-exec oai mkdir -p "${user_data_dir}"
fi

declare -a arg_list=(
    --disable-crash-reporter
    --disable-dev-shm-usage
    --disable-gpu
    --display="$DISPLAY"
    --enable-logging --v=1
    --force-device-scale-factor="${DISPLAY_SCALE_FACTOR}"
    --lang="en-US,en;q=0.9"
    --no-default-browser-check
    --no-first-run
    --remote-debugging-port="$CDP_PORT"
    --remote-allow-origins="http://localhost:${CDP_PORT}"
    --start-maximized
    --user-data-dir="${user_data_dir}"
    --window-position="0,0"
    --window-size="${DISPLAY_SIZE}"
)

if [[ "${TARGET}" == caas* ]]; then
    # shellcheck disable=SC2054
    arg_list+=(
        #
        # disable optimization model downloads and background updates
        # https://github.com/cypress-io/cypress/issues/22622
        # https://go.dev/solutions/google/chrome
        # https://chromium.googlesource.com/chromium/src/+/HEAD/components/optimization_guide/
        #
        --disable-features=OptimizationGuideModelDownloading,OptimizationHintsFetching,OptimizationTargetPrediction,OptimizationHints
        #
        # proxy loopback (localhost, 127.0.0.1, ::1, etc)
        # this ensures we log traffic in mitmproxy for observability
        # https://source.chromium.org/chromium/chromium/src/+/main:net/docs/proxy.md;drc=71698e610121078e0d1a811054dcf9fd89b49578;l=548
        #
        --proxy-server="$HTTP_PROXY"
        --proxy-bypass-list="<-loopback>"
    )
fi

# If this environment variable is set, override the user agent.
# This allows clients to specify different user agents without
# deploying new images.
if [ -n "${USER_AGENT}" ]; then
    arg_list+=(
        --user-agent="${USER_AGENT}"
    )
fi

# If this environment variable is set, it's possible that we expect
# to have cookies for chatgpt-staging.com. Therefore, we change the policy
# to use that instead.
if [ -n "${CHATGPT_URL}" ]; then
    sed -i "s/chatgpt\.com/$CHATGPT_URL/g" "${CHROMIUM_POLICY_DIR}/020_operator_search.json"
fi

if [ "$CI" = "true" ]; then
    arg_list+=(
        #
        # --no-sandbox required for chromium to start in buildkite pod
        # without this flag chromium fails to start and logs errors
        # https://buildkite.com/openai-mono/monorepo/builds/610973#01918311-4784-4b7e-ab49-f12fc0ae1d55
        #
        #   ==> /var/log/chrome.chromium.error.log <==
        #   Failed to move to new namespace: PID namespaces supported, Network namespace supported, but failed: errno = Operation not permitted
        #   [3862:3862:0824/063019.812628:FATAL:zygote_host_impl_linux.cc(201)] Check failed: . : Operation not permitted (1)
        #   [0824/063019.818576:WARNING:process_reader_linux.cc(95)] sched_getscheduler: Function not implemented (38)
        #   [0824/063019.818667:WARNING:process_reader_linux.cc(95)] sched_getscheduler: Function not implemented (38)
        #   ==> /var/log/chrome.supervisord.log <==
        #   2024-08-24 06:30:19,753 INFO spawned: 'chromium' with pid 3861
        #   2024-08-24 06:30:19,844 WARN exited: chromium (exit status 133; not expected)
        #
        --no-sandbox
        #
        # --test-type hides the warning which shows due to the above --no-sandbox flag
        # https://github.com/GoogleChrome/chrome-launcher/blob/main/docs/chrome-flags-for-tools.md
        #
        --test-type
    )
fi

homepage="${CHROMIUM_HOMEPAGE:-about:blank}"

echo "CI[${CI}]"
echo
echo "CHROMIUM_HOMEPAGE[${CHROMIUM_HOMEPAGE}]"
echo "homepage[${homepage}]"
echo
echo "NO_PROXY[${NO_PROXY}]"
echo "HTTP_PROXY[${HTTP_PROXY}]"
echo "HTTPS_PROXY[${HTTPS_PROXY}]"
echo "ALL_PROXY[${ALL_PROXY}]"
echo
echo "arg_list[${arg_list[*]}]"
echo

log_forwarder --service-name chrome -- su-exec oai chromium-browser "${arg_list[@]}" "$homepage"
