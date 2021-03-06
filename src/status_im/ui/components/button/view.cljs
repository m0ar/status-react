(ns status-im.ui.components.button.view
  (:require [status-im.ui.components.button.styles :as styles]
            [status-im.ui.components.colors :as colors]
            [status-im.ui.components.react :as react]
            [status-im.ui.components.icons.vector-icons :as vector-icons]
            [status-im.utils.platform :as platform]))

(defn button [{:keys [on-press style disabled? fit-to-text? text-style accessibility-label] :or {fit-to-text? true}} label icon]
  [react/touchable-highlight (merge {:underlay-color styles/border-color-high}
                                    (when-not fit-to-text?
                                      {:style styles/button-container})
                                    (when (and on-press (not disabled?))
                                      {:on-press on-press})
                                    (when accessibility-label
                                      {:accessibility-label accessibility-label}))
   [react/view {:style (merge styles/button
                              style)}
    [react/text {:style      (merge styles/button-text
                                    text-style
                                    (when disabled?
                                      {:opacity 0.4}))}
     label]
    icon]])

(defn primary-button [{:keys [style text-style] :as m} label]
  [button (assoc m
                 :style        (merge styles/primary-button style)
                 :text-style   (merge styles/primary-button-text text-style))
   label])

(defn secondary-button [{:keys [style text-style] :as m} label]
  [button (assoc m
                 :style        (merge styles/secondary-button style)
                 :text-style   (merge styles/secondary-button-text text-style))
   label])

(defn button-with-icon [{:keys [on-press label icon accessibility-label style]}]
  [react/touchable-highlight {:on-press on-press}
   [react/view (merge styles/button-with-icon-container style)
    [react/view styles/button-with-icon-text-container
     [react/text {:style styles/button-with-icon-text}
      label]]
    [react/view {:style               styles/button-with-icon-image-container
                 :accessibility-label accessibility-label}
     [vector-icons/icon icon {:color colors/blue}]]]])
