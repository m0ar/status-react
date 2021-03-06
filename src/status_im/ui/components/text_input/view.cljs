(ns status-im.ui.components.text-input.view
  (:require [status-im.ui.components.react :as react]
            [status-im.ui.components.text-input.styles :as styles]
            [status-im.ui.components.colors :as colors]
            [status-im.utils.platform :as platform]
            [status-im.ui.components.tooltip.views :as tooltip]))

(defn merge-container-styles
  [height container]
  (let [merged-styles (merge (styles/input-container height) container)]
    ;; `:background-color` can't be nil; in this case the app will crash.
    ;; Nevertheless, we need to be able to remove background if necessary.
    (if (nil? (:background-color merged-styles))
      (dissoc merged-styles :background-color)
      merged-styles)))

(defn text-input-with-label [{:keys [label content error style height container text] :as props}]
  [react/view
   (when label
     [react/text {:style styles/label}
      label])
   [react/view {:style (merge-container-styles height container)}
    [react/text-input
     (merge
      {:style                  (merge styles/input style)
       :placeholder-text-color colors/gray
       :auto-focus             true
       :auto-capitalize        :none}
      (dissoc props :style :height)
      ;; Workaround until `value` TextInput field is available on desktop:
      ;; https://github.com/status-im/react-native-desktop/issues/320
      (when-not platform/desktop?
        {:value text}))]
    (when content content)]
   (when error
     [tooltip/tooltip error (styles/error label)])])
