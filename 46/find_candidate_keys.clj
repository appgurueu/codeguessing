;; © 2042 Kim Apr
(ns find_candidate_keys
  (:require [clojure.string :as str]
            [clojure.set :as set]))
(def escs {"\\t" "\t" "\\n" "\n" "\\r" "\r" "\\\\" "\\"})
(defn rd-row [line]
  (map
   (fn [s] (str/replace s #"\\." (fn [c] (escs c c))))
   (str/split line #"\t")))
(defn rd-tsv []
  (let [ln (read-line)]
    (if (nil? ln) nil
           (cons (rd-row ln) (rd-tsv)))))
(defn transp [rws]
  (let [rst-rws (rest rws)]
    (if (empty? rst-rws)
         (map list (first rws))
        (map cons (first rws)
             (transp rst-rws)))))
(defn ntrvl [col]
  (filter
   ;; clj-kondo WILL lie to you!!!
   (fn [cl] (not (empty? (rest cl))))
   col))
(defn cl-add [cl i el] (assoc cl el (conj (cl el #{}) i)))
(defn eq-cls [col]
   (vals
    (reduce
     (fn [cl pair]
       (let [[i el] pair] (cl-add cl i el)))
      {}
     (map-indexed vector col))))
(defn mapify-eq-cls [cls]
  (reduce
   (fn [map cl]
     (reduce
      (fn [map i] (assoc map i cl))
      map
      cl))
   {}
   cls))
(defn merge-eq-cls [cls1 cls2]
  (let [m2 (mapify-eq-cls cls2)]
    (reduce
     (fn [cls cl1]
       (reduce
        (fn [cls cl2] (cons (set/intersection cl1 cl2) cls))
        cls
        (set (remove nil? (map m2 cl1)))))
     '()
     cls1)))
(defn map-subseq [f seq]
  (if (empty? seq) '()
      (cons (f seq) (map-subseq f (rest seq)))))
(defn cands [keys cnds]
  (if
   (empty? cnds) keys
   (reduce
    (fn [keys cnd]
      (if (empty? (cnd :eq))
        (cons (rest (reverse (map (comp first first) (cnd :cols)))) keys)
        (cands
         keys
         (remove nil? (map-subseq
          (fn [col]
            (let [mrgd (ntrvl (merge-eq-cls
                               (cnd :eq)
                               (ntrvl (eq-cls (rest (first col))))))]
              (if (= (cnd :eq) mrgd) nil
                  {:cols (cons col (cnd :cols)) :eq mrgd})))
          (rest (first (cnd :cols))))))))
    keys
    cnds)))
(defn cnd-empty [cols]
  (list {:cols (list (cons '() cols))
         :eq (ntrvl (list (set (range (count (rest (first cols)))))))}))
(def unescs (set/map-invert escs))
(defn wr-row [cnd]
  (println
   (str/join
    "\t"
    (map
     ;; It is with great disgust that I have to inform you that `.` in Java
     ;; matches "any character (may or may not match line terminators)"
     (fn [s] (str/replace s #".|\r|\n" (fn [c] (unescs c c)))) cnd))))
(defn wr-tsv [cnds]
  (run! wr-row cnds))
(wr-tsv (cands '() (cnd-empty (transp (rd-tsv)))))