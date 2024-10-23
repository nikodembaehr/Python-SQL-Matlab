#Comment about our assignment:
#For our clustering, we used 3 different methods which 
#can be seen in the data frame df, but for the computation of 
#assessment statistics, we mainly focused on the Levenshtein 
#method, which can be seen in F1statsdf data frame.


from collections import Counter
from unidecode import unidecode
import re
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.cluster import KMeans
from sklearn.metrics.pairwise import cosine_similarity
import pandas as pd
import networkx as nx
import matplotlib.pyplot as plt
import Levenshtein
from Levenshtein import ratio
import pyodbc as db
import statistics 
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.cluster import AgglomerativeClustering
from fuzzywuzzy import fuzz
from scipy import stats
from scipy.cluster.hierarchy import linkage, dendrogram
from scipy.spatial.distance import pdist
from scipy.cluster.hierarchy import fcluster
from sklearn.metrics import pairwise_distances
import numpy as np

'''
For our clustering, we used 3 different methods which can be seen in the data frame df,
but for the computation of assessment statistics, we mainly focused on the Levenshtein method,
which can be seen in F1statsdf data frame.
'''


# Establish the database connection

import pyodbc as db
import pandas as pd
from unidecode import unidecode
import re

# Establish the database connection
try:
    conn = db.connect('Driver={SQL Server};'
                      'Server=uvtsql.database.windows.net;'
                      'Database=db1;'
                      'uid=user31;'
                      'pwd=CompEco1234;')

    if conn is not None:
        print("The connection is established")
        sql_query = 'SELECT * FROM Patstat;'  # Use TOP to limit the number of rows
        sql_query2='select * from patstat_golden_set'
        data = pd.read_sql_query(sql_query, conn)
        datapatstatgold=pd.read_sql_query(sql_query2,conn)
        # Remove leading and trailing whitespaces from string columns
        data['npl_publn_id'] = data['npl_publn_id'].astype(str).str.strip()
        data['npl_biblio'] = data['npl_biblio'].astype(str).str.strip()

except Exception as e:
    print("Error:", e)

# Convert to lowercase, remove diacritics, and remove double or more white spaces
def clean_text(text):
    text = text.lower()
    text = unidecode(text)  # Remove diacritics
    text = re.sub(r'\s{2,}', ' ', text)  # Replace multiple white spaces with a single space
    return text

data['npl_publn_id'] = data['npl_publn_id'].apply(clean_text)
data['npl_biblio'] = data['npl_biblio'].apply(clean_text)

# Convert the cleaned DataFrame to a list
data_list = data.values.tolist()

#print(data_list)

def getAuthor(input_string):
    # Patterns to match "et al" and various punctuation marks
    termination_patterns = r"(et al|[\.\,\;\:\|])"
   
    # Match the author name based on defined criteria
    author_match = re.search(f"^(.*?)(?={termination_patterns})", input_string)
   
    if author_match:
        return author_match.group(1).strip()  # Trim any leading/trailing spaces
   
    return ''  # Return an empty string if no match is found


def get_issn_from_string(input_str):
    issn_list = re.findall(r'issn: [\w-]+', input_str)
    if issn_list:
        return issn_list[0]
    else:
        return None
    
def get_xp(input_string):
    pattern = r'xp\d{9}'  
    inputs = re.findall(pattern, input_string)
    if inputs:
        return inputs[0]
    else:
        return None
    
def get_vol(str):
    new_string = re.findall(r"vol\. (?:[1-9]\d{0,10})+",str)
    if new_string:
        return new_string[0]
    else:
        return None
    
def get_isbn(input_string):
    
    pattern = r'isbn:\s*[\d-]+'

    isbns = re.findall(pattern, input_string)
    if isbns:
        return isbns[0]
    else:
        return None
    
def get_tit_string(input_string):
    # Patterns to match the first and second punctuation
    punctuation_pattern1 = r"[^\w\s]"
    punctuation_pattern2 = r"[^\w\s,]"
    
    # Match everything between the first punctuation and the last part of the string
    match = re.search(f"{punctuation_pattern1}(.*$)", input_string)
    
    # If the match contains a '/', take the text after the last '/'
    if match:
        title = match.group(1).strip()
        # Check if "vol" is in the title, and if so, remove the part of the title after "vol"
        if "vol" in title.lower():
            title = title.split("vol", 1)[0].strip()
        
        # Check if the title starts with a comma, and if so, remove the leading comma
        if title.startswith(","):
            title = title[1:].strip()
        
        return title
    
    return None

   

def find_date(input_string):
    # Regular expression pattern to match dates of various formats
    date_pattern = r"\b\d{1,4}[-/\.]\d{1,2}[-/\.]\d{2,4}\b|\b(?:January|February|March|April|May|June|July|August|September|October|November|December)\s\d{2,4}\b"
   
    # Find the first match of the date pattern in the input string
    match = re.search(date_pattern, input_string)
   
    if match:
        return match.group()
    else:
        return None




def find_pages(input_string):
    # Regular expression pattern to match the text "pages," "pag," or "p" followed by numbers
    pages_pattern = r"(pages?|pags?|p|mpages?|mpags?)(\s+|\.|:)?(\d+[\s\-–]+\d+|\d+)"
 
   
    # Find the match in the input string
    match = re.search(pages_pattern, input_string, re.IGNORECASE)

    if match:
        return match.group()
    else:
        return None
def find_dois(text):
    doi_pattern = r"doi:\s*(10\.\d{4,}/[-._;()/:a-zA-Z0-9]+)|10\.\d{4,}/[-._;()/:a-zA-Z0-9]+"
    
    dois = re.findall(doi_pattern, text, re.IGNORECASE)
    if dois:
        return dois
    else:
        return None
    
def get_publisher(input_string):
    # Define regular expressions for publisher patterns
    publisher_patterns = [
        r"[A-Z\s&]+(?=\svol\.)",               # Matches publisher before "vol."
        r"[A-Z\s&]+(?=\d{4},\spages\s\d+)",   # Matches publisher before "YYYY, pages N - M"
        r"[A-Z\s&]+(?=\d{4},\s\d{2}-\s\d+)",  # Matches publisher before "YYYY, MM - DD"
    ]

    for pattern in publisher_patterns:
        match = re.search(pattern, input_string)
        if match:
            return match.group().strip()

    return None

def create_table(data):
    table_data = []

    for sublist in data:
        item_id = sublist[0]
        rest = sublist[1]
        pages = find_pages(rest)
        date = find_date(rest)
        author = getAuthor(rest)
        title = get_tit_string(rest)
        issn = get_issn_from_string(rest)
        xp = get_xp(rest)
        vol = get_vol(rest)
        isbn = get_isbn(rest)
        doi = find_dois(rest)
        publish= get_publisher(rest)

        table_data.append([item_id, author, issn, xp, vol, isbn, title, date, pages, vol, doi, publish])

    columns = ["id", "author", "issn", "xp", "vol", "isbn", "title", "date", "pages", "voliume", "DOI","Publisher"]
    df = pd.DataFrame(table_data, columns=columns)
    return df
def savedf(df):
    conn = None
    conn = db.connect('Driver={SQL Server};'
                      'Server=uvtsql.database.windows.net;'
                      'Database=db1;'
                      'uid=user31;'
                      'pwd=CompEco1234;')

    conn.execute(f"DROP TABLE group17_clusters")
    conn.commit()
    conn.execute(f"CREATE TABLE group17_clusters (npl_publn_id varchar(255),predicted_cluster varchar(255));")
    conn.commit()
    for index, row in df.iterrows():
        quer = "INSERT INTO group17_clusters (npl_publn_id,predicted_cluster) values('{}','{}')".format(str(row.npl_publn_id), str(row.cluster_id))
        conn.execute(quer)
        conn.commit()

    conn.close()

a=create_table(data_list)


result_table = create_table(data_list)

# Creating a Pandas DataFrame from the table data
df = pd.DataFrame(result_table)

# Assuming 'df' is your DataFrame created using the 'create_table' function

# Convert the specified columns to strings (and handle lists)
df['issn'] = df['issn'].apply(lambda x: ', '.join(x) if isinstance(x, list) else str(x))
df['xp'] = df['xp'].apply(lambda x: ', '.join(x) if isinstance(x, list) else str(x))
df['isbn'] = df['isbn'].apply(lambda x: ', '.join(x) if isinstance(x, list) else str(x))
df['DOI'] = df['DOI'].apply(lambda x: ', '.join(x) if isinstance(x, list) else str(x))

# Concatenate the columns to create a unique identifier
df['unique_codes'] = df['issn'] + df['xp'] + df['isbn'] + df['DOI']

# Group the DataFrame by the unique identifier
unique_codes_cluster = df.groupby('unique_codes')

# Assign a unique 'unique_codes_cluster_id' to each group
df['unique_codes_cluster_id'] = unique_codes_cluster.ngroup()

# Drop the temporary 'unique_codes' column
df.drop('unique_codes', axis=1, inplace=True)

# Print the 'unique_codes_cluster_id'



#####now we cosine cluster



# Combine 'author', 'title', and 'pages' into a single text field for each publication
df['text_combined'] = df['issn'].fillna('') + ' ' + df['xp'].fillna('') + ' ' + df['vol'].fillna('')+''+ df['isbn'].fillna('') + ' ' + df['pages'].fillna('') + ' ' + df['date'].fillna('')+ ' ' + df['title'].fillna('')

# TF-IDF Vectorization
vectorizer = TfidfVectorizer(stop_words='english')
tfidf_matrix = vectorizer.fit_transform(df['text_combined'])
# Compute Cosine Similarity
cosine_sim = cosine_similarity(tfidf_matrix, tfidf_matrix)
# Apply K-Means Clustering
num_clusters = 100  # now we know how many clusters we should find, but in reality we could try to do a Gap Statistic to find the optimum k
kmeans = KMeans(n_clusters=num_clusters)
kmeans.fit(tfidf_matrix)
df['cosine_cluster'] = kmeans.labels_



df_final = pd.DataFrame()
results = datapatstatgold.copy()
cluster=0
while len(results) != 0:
    cluster += 1
    #row is the npl_biblio_extract of the first publication in the table
    point = results['npl_biblio'].iloc[0]
        
    
    aa = results['npl_biblio'].apply(lambda x: ratio(point,x)).loc[lambda x: x>0.6].index
        
    results.loc[aa, 'predicted_cluster'] = cluster
        
    df_final = df_final._append(results.loc[aa], ignore_index=True)
    results.drop(aa, inplace = True)

# Create a new column 'lev_cluster_id' in the original DataFrame based on cluster assignments

print(df[['cosine_cluster','unique_codes_cluster_id','id']])

#In Calclulations of precision we use levenstein

#statistacs
most_common_clusters = df_final.groupby('cluster_id')['predicted_cluster'].apply(lambda x: x.value_counts().idxmax()).reset_index()
most_common_value = most_common_clusters['predicted_cluster'].value_counts()


# Group the data by 'cluster_id' and calculate the count of the most common 'predicted_cluster'
TP = df_final.groupby('cluster_id')['predicted_cluster'].apply(lambda x: x.value_counts().max())
# Calculate the total count for each 'cluster_id'
total_counts = df_final['cluster_id'].value_counts()
most_common_clusters['occurrences'] = most_common_clusters['predicted_cluster'].apply(lambda x: (df_final['predicted_cluster'] == x).sum())
occurences=most_common_clusters['occurrences'].tolist()
FP= occurences  - TP
# Calculate the count of other 'predicted_clusters'
FN = total_counts - TP 
# Create a DataFrame to display the results
result_df = pd.DataFrame({
    'True Positives': TP,
    'False Negatives': FN,
    'False positives':FP
})

recall=TP/total_counts
recall.name='recall'
precision=TP/(TP+FP)
precision.name='precision'
f1=2*precision*recall/(precision+recall)
f1.name='f1'
f1mean=f1.mean()

statistics=pd.DataFrame()
statistics['recall']=recall
statistics['precision']=precision
statistics['f1']=f1


f1list=f1.tolist()
f1fix=pd.Series(f1list)
prelist=precision.tolist()
precisionfix=pd.Series(prelist)
F1statsdf= pd.DataFrame({
    "recall" : recall,
    "precision" : prelist,
    "f1" : f1list
    
})

prelist=precision.tolist()
precisionfix=pd.Series(prelist)
F1statsdf= pd.DataFrame({
    "recall" : recall,
    "precision" : prelist,
    "f1" : f1list
})

F1statsdf.to_excel("ClusterF1.xlsx")

plt.bar(F1statsdf.index, F1statsdf['f1'])
plt.xlabel('Cluster id')
plt.ylabel('F1 value')
plt.title(' Plot of f1 based on cluster id')
plt.savefig('F1plot.png')

plt.bar(F1statsdf.index, F1statsdf['precision'])
plt.xlabel('Cluster id')
plt.ylabel('precision value')
plt.title(' Plot of precision based on cluster id')
plt.savefig('precisionplot.png')

plt.bar(F1statsdf.index, F1statsdf['recall'])
plt.xlabel('Cluster id')
plt.ylabel('Recall value')
plt.title(' Plot of recall based on cluster id')
plt.savefig('recallplot.png')

savedf(df_final)

