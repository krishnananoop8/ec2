

if [ "$1" = "--help" ] || [ "$1" = "--?" ]; then
  echo "This script runs SGD and Bayes classifiers over the cnn data set."
  exit
fi

SCRIPT_PATH=${0%/*}
if [ "$0" != "$SCRIPT_PATH" ] && [ "$SCRIPT_PATH" != "" ]; then
  cd $SCRIPT_PATH
fi
START_PATH=`pwd`

algorithm=(cnaivebayes naivebayes)
if [ -n "$1" ]; then
  choice=$1
else
  echo "Please select a number to choose the corresponding task to run"
  echo "1. ${algorithm[0]}"
  echo "2. ${algorithm[1]}"
  read -p "Enter your choice : " choice
fi

echo "ok. You chose $choice and we'll use ${algorithm[$choice-1]}"
alg=${algorithm[$choice-1]}


if [ "x$alg" == "xnaivebayes"  -o  "x$alg" == "xcnaivebayes" ]; then
  c=""

  if [ "x$alg" == "xcnaivebayes" ]; then
    c=" -c"
  fi

  echo "Creating sequence files from cnn data"
  mahout seqdirectory \
    -i cnn_classify/data \
    -o cnn_classify/data-seq

  echo "Converting sequence files to vectors"
  mahout seq2sparse \
    -i cnn_classify/data-seq \
    -o cnn_classify/data-vectors  -lnorm -nv  -wt tfidf

  echo "Creating training and holdout set with a random 80-20 split of the generated vector dataset"
  mahout split \
    -i cnn_classify/data-vectors/tfidf-vectors \
    --trainingOutput cnn_classify/data-train-vectors \
    --testOutput cnn_classify/data-test-vectors  \
    --randomSelectionPct 40 --overwrite --sequenceFiles -xm sequential

  echo "Training Naive Bayes model"
  mahout trainnb \
    -i cnn_classify/data-train-vectors -el \
    -o cnn_classify/model \
    -li cnn_classify/labelindex \
    -ow $c

  echo "Self testing on training set"

  mahout testnb \
    -i cnn_classify/data-train-vectors\
    -m cnn_classify/model \
    -l cnn_classify/labelindex \
    -ow -o cnn_classify/data-testing $c

  echo "Testing on holdout set"

  mahout testnb \
    -i cnn_classify/data-test-vectors\
    -m cnn_classify/model \
    -l cnn_classify/labelindex \
    -ow -o cnn_classify/data-testing $c

fi
