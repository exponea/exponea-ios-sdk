import SwiftUI

// Accessibility identifiers for UI automation, listed in Tests/Contract/automation_contract.yaml.
// Most names match the other Bloomreach SDK example apps, so keep them stable.
// Apply via .accessibilityIdentifier(A11yID.auth.start)
enum A11yID {

    enum auth {
        static let title              = "lbl_auth_title"
        static let modeProject        = "btn_auth_mode_project"
        static let modeStream         = "btn_auth_mode_stream"
        static let projectToken       = "fld_auth_project_token"
        static let authToken          = "fld_auth_authorization_token"
        static let advancedAuth       = "fld_auth_advanced_auth"
        static let streamId           = "fld_auth_stream_id"
        static let jwtKeyId           = "fld_auth_jwt_key_id"
        static let jwtSecret          = "fld_auth_jwt_secret"
        static let registeredId       = "fld_auth_registered_id"
        static let apiUrl             = "fld_auth_api_url"
        static let applicationId      = "fld_auth_application_id"
        static let start              = "btn_auth_start"
        static let clearLocalData     = "btn_auth_clear_local_data"
    }

    enum fetching {
        static let fetchConsents              = "btn_fetch_consents"
        static let fetchRecommendations       = "btn_fetch_recommendations"
        static let fetchSegments              = "btn_fetch_segments"
        static let appInboxProvider           = "btn_app_inbox_provider"
        static let openInbox                  = "btn_open_inbox"
        static let clearResult                = "btn_clear_result"
        static let fetchResult                = "lbl_fetch_result"
        static let fetchLoading               = "status_fetch_loading"
        static let recommendationId           = "fld_recommendation_id"
        static let recommendationDialogFetch  = "btn_recommendation_dialog_fetch"
        static let recommendationDialogCancel = "btn_recommendation_dialog_cancel"
    }

    enum appInbox {
        static let title        = "lbl_app_inbox_title"
        static let back         = "btn_app_inbox_back"
        static let list         = "list_app_inbox"
        static let detailTitle  = "lbl_app_inbox_detail_title"
        static let detailBack   = "btn_app_inbox_detail_back"
        static let detailView   = "view_app_inbox_detail"
    }

    enum tracking {
        static let cookieId           = "lbl_cookie_id"
        static let copyCookieId       = "btn_copy_cookie_id"
        static let identifyCustomer   = "btn_identify_customer"
        static let setAuthToken       = "btn_set_auth_token"
        static let customEvent        = "btn_track_custom_event"
        static let payment            = "btn_track_payment"
        static let pageView           = "btn_track_page_view"
        static let requestPush        = "btn_request_push"
        static let fcmToken           = "btn_track_fcm_token"
        static let deliveredPush      = "btn_track_push_delivered"
        static let clickedPush        = "btn_track_push_clicked"
        static let identify           = "btn_identify"
        static let identifyAuth       = "btn_identify_auth"
        static let registeredId       = "fld_registered_id"
        static let registeredIdLabel  = "lbl_registered_id"
        static let identifyAttrName   = "fld_identify_attr_name"
        static let identifyAttrValue  = "fld_identify_attr_value"
        static let identifyAddAttr    = "btn_identify_add_attr"
        static let identifyAttrsJson  = "lbl_identify_attrs_json"
        static let inappPreset        = "sel_inapp_preset"
        static let eventName          = "fld_event_name"
        static let eventAttrName      = "fld_event_attr_name"
        static let eventAttrValue     = "fld_event_attr_value"
        static let eventAddAttr       = "btn_event_add_attr"
        static let eventPropsJson     = "lbl_event_props_json"
        static let trackEvent         = "btn_track_event"
    }

    enum flushing {
        static let tabFlushMode       = "tab_flush_mode"
        static let tabFlushPeriod     = "tab_flush_period"
        static let tabLogLevel        = "tab_log_level"
        static let getFlushMode       = "btn_get_flush_mode"
        static let currentFlushMode   = "lbl_current_flush_mode"
        static let modeImmediate      = "btn_flush_mode_immediate"
        static let modePeriod         = "btn_flush_mode_period"
        static let modeAppClose       = "btn_flush_mode_app_close"
        static let modeManual         = "btn_flush_mode_manual"
        static let getFlushPeriod     = "btn_get_flush_period"
        static let currentFlushPeriod = "lbl_current_flush_period"
        static let period30           = "btn_flush_period_30"
        static let period60           = "btn_flush_period_60"
        static let flushData          = "btn_flush_data"
        static let flushResultTitle   = "lbl_flush_result_title"
        static let flushResultOk      = "btn_flush_result_ok"
        static let getLogLevel        = "btn_get_log_level"
        static let currentLogLevel    = "lbl_current_log_level"
        static let logOff             = "btn_log_off"
        static let logError           = "btn_log_error"
        static let logWarn            = "btn_log_warn"
        static let logInfo            = "btn_log_info"
        static let logDebug           = "btn_log_debug"
        static let logVerbose         = "btn_log_verbose"
    }

    enum anonymize {
        static let anonymize            = "btn_anonymize"
        static let stopIntegration      = "btn_stop_integration"
        static let anonymizedTitle      = "lbl_anonymized_title"
        static let anonymizedOk         = "btn_anonymized_ok"
        static let stopBackToAuth       = "btn_stop_back_to_auth"
        static let stopStopAndContinue  = "btn_stop_continue"
        static let stopCancel           = "btn_stop_cancel"
    }

    enum contentBlocks {
        static let toggleCarousels       = "btn_toggle_carousels"
        static let placeholderTop        = "cb_placeholder_example_top"
        static let placeholderPlatform   = "cb_placeholder_example_platform"
        static let placeholderList         = "cb_placeholder_example_list"
        static let carouselDefault         = "cb_carousel_default"
        static let carouselFiltered        = "cb_carousel_filtered"
        static let carouselPlatform        = "cb_carousel_platform"
        static let carouselStatus          = "lbl_carousel_status"
        static let tabClassic              = "cb_tab_classic"
        static let tabRuntimeLab           = "cb_tab_runtime_lab"
        static let runtimeIdsInput         = "cb_runtime_ids_input"
        static let runtimeDeadlineInput    = "cb_runtime_deadline_input"
        static let runtimePrefetch         = "btn_cb_runtime_prefetch"
        static let runtimeAvailability     = "btn_cb_runtime_availability"
        static let runtimeInvalidate       = "btn_cb_runtime_invalidate"
        static let runtimeLogout           = "btn_cb_runtime_logout"
        static let runtimeStatus           = "lbl_cb_runtime_status"

        static func placeholderHeight(_ placeholderId: String) -> String {
            "lbl_cb_height_\(placeholderId)"
        }
    }

    enum shell {
        static let navFetching           = "btn_nav_fetching"
        static let navTracking           = "btn_nav_tracking"
        static let navFlushing           = "btn_nav_flushing"
        static let navAnonymize          = "btn_nav_anonymize"
        static let navContentBlocks      = "btn_nav_content_blocks"
        static let openLogs              = "btn_open_logs"
        static let resetState            = "btn_reset_state"
        static let resetBackToAuth       = "btn_reset_back_to_auth"
        static let resetStopAndContinue  = "btn_reset_stop_and_continue"
        static let resetCancel           = "btn_reset_cancel"
        static let shellLogo             = "btn_shell_logo"
        static let loadingLogo           = "img_loading_logo"
        static let statusIndicator       = "status_sdk_indicator"
        static let configClose           = "btn_config_close"
        static let configNotConfigured   = "lbl_config_not_configured"
    }

    enum logs {
        static let close        = "btn_logs_close"
        static let copyButton   = "btn_logs_copy"
        static let clearButton  = "btn_logs_clear"
        static let filterAll    = "btn_logs_filter_all"
        static let filterVerbose = "btn_logs_filter_verbose"
        static let filterDebug  = "btn_logs_filter_debug"
        static let filterInfo   = "btn_logs_filter_info"
        static let filterWarn   = "btn_logs_filter_warn"
        static let filterError  = "btn_logs_filter_error"
        static let list         = "list_logs"
        static let empty        = "lbl_logs_empty"
    }
}
