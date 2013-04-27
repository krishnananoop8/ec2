
if [ "$1" = "--help" ] || [ "$1" = "--?" ]; then
  echo "This script clusters the cnn data set using a variety of algorithms."
  exit
fi

SCRIPT_PATH=${0%/*}
if [ "$0" != "$SCRIPT_PATH" ] && [ "$SCRIPT_PATH" != "" ]; then 
  cd $SCRIPT_PATH
fi



algorithm=(kmeans fuzzykmeans dirichlet minhash)
if [ -n "$1" ]; then
  choice=$1
else
  echo "Please select a number to choose the corresponding clustering algorithm"
  echo "1. ${algorithm[0]} clustering"
  echo "2. ${algorithm[1]} clustering"
  echo "3. ${algorithm[2]} clustering"
  echo "4. ${algorithm[3]} clustering"
  read -p "Enter your choice : " choice
fi

echo "ok. You chose $choice and we'll use ${algorithm[$choice-1]} Clustering"
clustertype=${algorithm[$choice-1]} 

hadoop fs -mkdir -p cluster_cnn/cnn-seqdir
mahout seqdirectory -i cluster_cnn/data -o cluster_cnn/cnn-seqdir -c UTF-8 -chunk 5


if [ "x$clustertype" == "xkmeans" ]; then
  mahout seq2sparse \
    -i cluster_cnn/cnn-seqdir/ \
    -o cluster_cnn/cnn-seqdir-sparse-kmeans --maxDFPercent 85 --namedVector \
  && \
  mahout kmeans \
    -i cluster_cnn/cnn-seqdir-sparse-kmeans/tfidf-vectors/ \
    -c cluster_cnn/cnn-kmeans-clusters \
    -o cluster_cnn/cnn-kmeans \
    -dm org.apache.mahout.common.distance.CosineDistanceMeasure \
    -x 10 -k 20 -ow --clustering \
  && \
  mahout clusterdump \
    -i cluster_cnn/cnn-kmeans/clusters-*-final \
    -o cluster_cnn/clusterdump \
    -d cluster_cnn/cnn-seqdir-sparse-kmeans/dictionary.file-0 \
    -dt sequencefile -b 100 -n 5 --evaluate -dm org.apache.mahout.common.distance.CosineDistanceMeasure -sp 0 \
    --pointsDir cluster_cnn/cnn-kmeans/clusteredPoints \
    && \
  hadoop fs -cat cluster_cnn/clusterdump
elif [ "x$clustertype" == "xfuzzykmeans" ]; then
  mahout seq2sparse \
    -i reuters-out-seqdir/ \
    -o reuters-out-seqdir-sparse-fkmeans --maxDFPercent 85 --namedVector \
  && \
  mahout fkmeans \
    -i reuters-out-seqdir-sparse-fkmeans/tfidf-vectors/ \
    -c reuters-fkmeans-clusters \
    -o reuters-fkmeans \
    -dm org.apache.mahout.common.distance.CosineDistanceMeasure \
    -x 10 -k 20 -ow -m 1.1 \
  && \
  mahout clusterdump \
    -i reuters-fkmeans/clusters-*-final \
    -o reuters-fkmeans/clusterdump \
    -d reuters-out-seqdir-sparse-fkmeans/dictionary.file-0 \
    -dt sequencefile -b 100 -n 20 -sp 0 \
    && \
  cat reuters-fkmeans/clusterdump
elif [ "x$clustertype" == "xdirichlet" ]; then
  mahout seq2sparse \
    -i reuters-out-seqdir/ \
    -o reuters-out-seqdir-sparse-dirichlet  --maxDFPercent 85 --namedVector \
  && \
  mahout dirichlet \
    -i reuters-out-seqdir-sparse-dirichlet/tfidf-vectors \
    -o reuters-dirichlet -k 20 -ow -x 20 -a0 2 \
    -md org.apache.mahout.clustering.dirichlet.models.DistanceMeasureClusterDistribution \
    -mp org.apache.mahout.math.DenseVector \
    -dm org.apache.mahout.common.distance.CosineDistanceMeasure \
  && \
  mahout clusterdump \
    -i reuters-dirichlet/clusters-*-final \
    -o reuters-dirichlet/clusterdump \
    -d reuters-out-seqdir-sparse-dirichlet/dictionary.file-0 \
    -dt sequencefile -b 100 -n 20 -sp 0 \
    && \
  cat reuters-dirichlet/clusterdump
elif [ "x$clustertype" == "xminhash" ]; then
  mahout seq2sparse \
    -i reuters-out-seqdir/ \
    -o reuters-out-seqdir-sparse-minhash --maxDFPercent 85 --namedVector \
  && \
  mahout org.apache.mahout.clustering.minhash.MinHashDriver \
    -i reuters-out-seqdir-sparse-minhash/tfidf-vectors \
    -o reuters-minhash --overwrite
else 
  echo "unknown cluster type: $clustertype"
fi 
