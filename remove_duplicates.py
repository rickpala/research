import sys
import pandas as pd



if __name__=="__main__":
    filename = str(sys.argv[1])
    df = pd.read_json(path_or_buf=filename)
    nrows = df.shape[0]
    df = df.drop_duplicates(subset=['id'])
    print("Dropped {0} duplicate rows".format(nrows - df.shape[0]))
    df.to_json(path_or_buf="nodup_{0}".format(filename))