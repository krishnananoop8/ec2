

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
    -i classify_cnn/data \
    -o classify_cnn/data-seq

  echo "Converting sequence files to vectors"
  mahout seq2sparse \
    -i classify_cnn/data-seq \
    -o classify_cnn/data-vectors  -lnorm -nv  -wt tfidf

  echo "Creating training and holdout set with a random 80-20 split of the generated vector dataset"
  mahout split \
    -i classify_cnn/data-vectors/tfidf-vectors \
    --trainingOutput classify_cnn/data-train-vectors \
    --testOutput classify_cnn/data-test-vectors  \
    --randomSelectionPct 40 --overwrite --sequenceFiles -xm sequential

  echo "Training Naive Bayes model"
  mahout trainnb \
    -i classify_cnn/data-train-vectors -el \
    -o classify_cnn/model \
    -li classify_cnn/labelindex \
    -ow $c

  echo "Self testing on training set"

  mahout testnb \
    -i classify_cnn/data-train-vectors\
    -m classify_cnn/model \
    -l classify_cnn/labelindex \
    -ow -o classify_cnn/data-testing $c

  echo "Testing on holdout set"

  mahout testnb \
    -i classify_cnn/data-test-vectors\
    -m classify_cnn/model \
    -l classify_cnn/labelindex \
    -ow -o classify_cnn/data-testing $c

fi
