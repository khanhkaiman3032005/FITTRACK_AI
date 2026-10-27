"""Train a reproducible Vietnamese intent classifier and export portable JSON.
Requires: pip install scikit-learn. Training examples are a small starter dataset,
NOT evidence of real-world reliability. Add real, consented, anonymized examples.
"""
import csv, json, math, pathlib, random
from collections import Counter
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score, confusion_matrix
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.naive_bayes import MultinomialNB

ROOT = pathlib.Path(__file__).resolve().parents[1]
DATA=ROOT/'tools'/'intent_questions.csv'
OUT=ROOT/'assets'/'ai'/'intent_nb.json'
rows=list(csv.DictReader(DATA.open(encoding='utf-8-sig')))
texts=[r['text'] for r in rows]; labels=[r['intent'] for r in rows]
# Character n-grams capture accents and spelling variations without external tokenizer.
vec=CountVectorizer(analyzer='char',ngram_range=(2,3),lowercase=True,binary=True,min_df=1)
# Keep a reproducible holdout. Never train on the test samples.
xtrain,xtest,ytrain,ytest=train_test_split(texts,labels,test_size=0.25,random_state=42,stratify=labels)
X=vec.fit_transform(xtrain)
model=MultinomialNB(alpha=1.0).fit(X,ytrain)
pred=model.predict(vec.transform(xtest))
print('Held-out evaluation (small illustrative dataset; not a production benchmark)')
print('n train:',len(xtrain),'n test:',len(xtest),'accuracy:',round(accuracy_score(ytest,pred),3))
print(classification_report(ytest,pred,zero_division=0))
print('confusion matrix labels:',list(model.classes_))
print(confusion_matrix(ytest,pred,labels=model.classes_))
# Feature values are binary, matching the Dart inference. All active features contribute once.
# Export sparse per-class log-likelihoods with an explicit absent-token default.
feature_names=vec.get_feature_names_out().tolist()
obj={'version':1,'model':'multinomial_nb_char_binary','ngram_min':2,'ngram_max':3,
     'classes':model.classes_.tolist(),
     'class_log_prior':[float(x) for x in model.class_log_prior_],
     'feature_log_prob':{f:[float(model.feature_log_prob_[i,j]) for i in range(len(model.classes_))]
                         for j,f in enumerate(feature_names)},
     'confidence_threshold':0.80,'margin_threshold':0.25,
     'note':'Training data is a small synthetic starter dataset. Needs independent testing.'}
OUT.parent.mkdir(parents=True,exist_ok=True)
OUT.write_text(json.dumps(obj,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
print('model:',OUT,'bytes:',OUT.stat().st_size)
