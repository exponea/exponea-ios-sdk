import SwiftUI

// Accessibility identifiers for UI automation, listed in Tests/Contract/automation_contract.yaml.
// Most names match the other Bloomreach SDK example apps, so keep them stable.
// Apply via .accessibilityIdentifier(A11yID.auth.start)
// Each namespace is a struct with stored `let` properties so ExampleTests can list every ID with Mirror;
// a `static let` ID would be invisible to the contract test. A new namespace must also be added to
// `appNamespaces` in AccessibilityContractTests, or its IDs escape the contract check.
enum A11yID {

    static let auth = Auth()

    struct Auth {
        let title              = "lbl_auth_title"
        let modeProject        = "btn_auth_mode_project"
        let modeStream         = "btn_auth_mode_stream"
        let projectToken       = "fld_auth_project_token"
        let authToken          = "fld_auth_authorization_token"
        let advancedAuth       = "fld_auth_advanced_auth"
        let streamId           = "fld_auth_stream_id"
        let jwtKeyId           = "fld_auth_jwt_key_id"
        let jwtSecret          = "fld_auth_jwt_secret"
        let registeredId       = "fld_auth_registered_id"
        let apiUrl             = "fld_auth_api_url"
        let applicationId      = "fld_auth_application_id"
        let start              = "btn_auth_start"
        let clearLocalData     = "btn_auth_clear_local_data"
    }

    static let fetching = Fetching()

    struct Fetching {
        let fetchConsents              = "btn_fetch_consents"
        let fetchRecommendations       = "btn_fetch_recommendations"
        let fetchSegments              = "btn_fetch_segments"
        let appInboxProvider           = "btn_app_inbox_provider"
        let openInbox                  = "btn_open_inbox"
        let clearResult                = "btn_clear_result"
        let fetchResult                = "lbl_fetch_result"
        let fetchLoading               = "status_fetch_loading"
        let recommendationId           = "fld_recommendation_id"
        let recommendationDialogFetch  = "btn_recommendation_dialog_fetch"
        let recommendationDialogCancel = "btn_recommendation_dialog_cancel"
    }

    static let appInbox = AppInbox()

    struct AppInbox {
        let title        = "lbl_app_inbox_title"
        let back         = "btn_app_inbox_back"
        let list         = "list_app_inbox"
        let detailTitle  = "lbl_app_inbox_detail_title"
        let detailBack   = "btn_app_inbox_detail_back"
        let detailView   = "view_app_inbox_detail"
    }

    static let tracking = Tracking()

    struct Tracking {
        let cookieId           = "lbl_cookie_id"
        let copyCookieId       = "btn_copy_cookie_id"
        let identifyCustomer   = "btn_identify_customer"
        let setAuthToken       = "btn_set_auth_token"
        let customEvent        = "btn_track_custom_event"
        let payment            = "btn_track_payment"
        let pageView           = "btn_track_page_view"
        let requestPush        = "btn_request_push"
        let fcmToken           = "btn_track_fcm_token"
        let deliveredPush      = "btn_track_push_delivered"
        let clickedPush        = "btn_track_push_clicked"
        let identify           = "btn_identify"
        let identifyAuth       = "btn_identify_auth"
        let registeredId       = "fld_registered_id"
        let registeredIdLabel  = "lbl_registered_id"
        let identifyAttrName   = "fld_identify_attr_name"
        let identifyAttrValue  = "fld_identify_attr_value"
        let identifyAddAttr    = "btn_identify_add_attr"
        let identifyAttrsJson  = "lbl_identify_attrs_json"
        let inappPreset        = "sel_inapp_preset"
        let eventName          = "fld_event_name"
        let eventAttrName      = "fld_event_attr_name"
        let eventAttrValue     = "fld_event_attr_value"
        let eventAddAttr       = "btn_event_add_attr"
        let eventPropsJson     = "lbl_event_props_json"
        let trackEvent         = "btn_track_event"
    }

    static let flushing = Flushing()

    struct Flushing {
        let tabFlushMode       = "tab_flush_mode"
        let tabFlushPeriod     = "tab_flush_period"
        let tabLogLevel        = "tab_log_level"
        let getFlushMode       = "btn_get_flush_mode"
        let currentFlushMode   = "lbl_current_flush_mode"
        let modeImmediate      = "btn_flush_mode_immediate"
        let modePeriod         = "btn_flush_mode_period"
        let modeAppClose       = "btn_flush_mode_app_close"
        let modeManual         = "btn_flush_mode_manual"
        let getFlushPeriod     = "btn_get_flush_period"
        let currentFlushPeriod = "lbl_current_flush_period"
        let period30           = "btn_flush_period_30"
        let period60           = "btn_flush_period_60"
        let flushData          = "btn_flush_data"
        let flushResultOk      = "btn_flush_result_ok"
        let getLogLevel        = "btn_get_log_level"
        let currentLogLevel    = "lbl_current_log_level"
        let logOff             = "btn_log_off"
        let logError           = "btn_log_error"
        let logWarn            = "btn_log_warn"
        let logInfo            = "btn_log_info"
        let logDebug           = "btn_log_debug"
        let logVerbose         = "btn_log_verbose"
    }

    static let anonymize = Anonymize()

    struct Anonymize {
        let anonymize            = "btn_anonymize"
        let stopIntegration      = "btn_stop_integration"
        let anonymizedOk         = "btn_anonymized_ok"
        let stopBackToAuth       = "btn_stop_back_to_auth"
        let stopStopAndContinue  = "btn_stop_continue"
        let stopCancel           = "btn_stop_cancel"
    }

    static let contentBlocks = ContentBlocks()

    struct ContentBlocks {
        let toggleCarousels       = "btn_toggle_carousels"
        let placeholderTop        = "cb_placeholder_example_top"
        let placeholderPlatform   = "cb_placeholder_example_platform"
        let placeholderList         = "cb_placeholder_example_list"
        let carouselDefault         = "cb_carousel_default"
        let carouselFiltered        = "cb_carousel_filtered"
        let carouselPlatform        = "cb_carousel_platform"
        let carouselStatus          = "lbl_carousel_status"
        let tabClassic              = "cb_tab_classic"
        let tabRuntimeLab           = "cb_tab_runtime_lab"
        let runtimeIdsInput         = "cb_runtime_ids_input"
        let runtimeDeadlineInput    = "cb_runtime_deadline_input"
        let runtimePrefetch         = "btn_cb_runtime_prefetch"
        let runtimeAvailability     = "btn_cb_runtime_availability"
        let runtimeInvalidate       = "btn_cb_runtime_invalidate"
        let runtimeLogout           = "btn_cb_runtime_logout"
        let runtimeStatus           = "lbl_cb_runtime_status"

        func placeholderHeight(_ placeholderId: String) -> String {
            "lbl_cb_height_\(placeholderId)"
        }
    }

    static let shell = Shell()

    struct Shell {
        let navFetching           = "btn_nav_fetching"
        let navTracking           = "btn_nav_tracking"
        let navFlushing           = "btn_nav_flushing"
        let navAnonymize          = "btn_nav_anonymize"
        let navContentBlocks      = "btn_nav_content_blocks"
        let openLogs              = "btn_open_logs"
        let resetState            = "btn_reset_state"
        let resetBackToAuth       = "btn_reset_back_to_auth"
        let resetStopAndContinue  = "btn_reset_stop_and_continue"
        let resetCancel           = "btn_reset_cancel"
        let shellLogo             = "btn_shell_logo"
        let loadingLogo           = "img_loading_logo"
        let statusIndicator       = "status_sdk_indicator"
        let configClose           = "btn_config_close"
        let configNotConfigured   = "lbl_config_not_configured"
    }

    static let logs = Logs()

    struct Logs {
        let close        = "btn_logs_close"
        let copyButton   = "btn_logs_copy"
        let clearButton  = "btn_logs_clear"
        let filterAll    = "btn_logs_filter_all"
        let filterVerbose = "btn_logs_filter_verbose"
        let filterDebug  = "btn_logs_filter_debug"
        let filterInfo   = "btn_logs_filter_info"
        let filterWarn   = "btn_logs_filter_warn"
        let filterError  = "btn_logs_filter_error"
        let list         = "list_logs"
        let empty        = "lbl_logs_empty"
    }
}
