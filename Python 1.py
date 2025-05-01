import itertools
import pandas as pd
import pyodbc as db
import re
import unicodedata
from datetime import datetime
import Levenshtein
import numpy as np
import networkx as nx
from tqdm import tqdm
import matplotlib.pyplot as plt

# To apply OOP learned during classes I divided each step of the process into its own class, with methods that handle specific functionalities:

# Data Processor class - handles data preprocessing

class DataPreprocessor:
    
    def __init__(self):
        # Creating this class establish data base connection to handle data from the database:
        self.raw_data = None
        self.preprocessed_data = None

    def connect_to_db(self):
        query = "select * from Patstat_golden_set" # Change sample here
        try:
            conn = db.connect('Driver={SQL Server};'
                                'Server=uvtsql.database.windows.net;'
                                'Database=db3;'
                                'uid=user71;'
                                'pwd=CompEco1234;')
            self.raw_data = pd.read_sql_query(query, conn)
            conn.close()
            print("Data loaded!")
        except Exception as e:
            print("Error connecting to the data base: ", e)

    def clean_entry(self, text):
        """
        Cleans the input text by removing leading and trailing spaces,
        multiple white spaces, diacritics, capitalization, and irrelevant punctuation.
        """
        # Remove leading and trailing spaces
        text = text.strip()
        # Remove diacritics
        text = unicodedata.normalize('NFKD', text).encode('ascii', 'ignore').decode('utf-8')
        # Convert to lowercase
        text = text.lower()
        # Remove irrelevant punctuation - keep only alphanumeric characters, spaces, and hyphens
        text = re.sub(r'[^\w\s-]', ' ', text)
        #  Replace multiple white spaces with a single space
        text = re.sub(r'\s+', ' ', text)

        return text
    
    def preprocess_data(self):
        processed_records = []

        # Iterate over each row in the DataFrame as a dictionary
        for _, row in self.raw_data.iterrows():
            npl_publn_id = row["npl_publn_id"]
            cleaned_record = self.clean_entry(row["npl_biblio"])
            processed_records.append({"npl_publn_id":npl_publn_id, "npl_biblio_cleaned":cleaned_record})

        # Store the cleaned records as a DataFrame
        self.cleaned_data = pd.DataFrame(processed_records)

    # All functions that extract meta data:

    def extract_xp_number(self, text):
        # Define the pattern to find 'xp' followed by any alphanumeric characters and hyphens
        xp_pattern = r'\b(xp[-\w]+)\b'
        
        # Search for the pattern in the input text
        match = re.search(xp_pattern, text, re.IGNORECASE)
        
        # If a match is found, return it
        if match:
            return match.group(0)
        else:
            return "NULL"

    
    def extract_issn(self,text):
        """"
        Function to extract issn based on the 8-digit pattern,
        it is based on this website information: 
        https://www.issn.org/understanding-the-issn/what-is-an-issn/#:~:text=The%20eighth%20digit%20is%20a,ISSN%200317%2D8471
        """

        # Define the ISSN pattern with 8 digits and a hyphen
        issn_pattern = r'\b\d{4}-\d{4}\b'
        issn_pattern_with_x = r'\b\d{4}-\d{3}[0-9xX]\b'
        
        # Search for the standard ISSN pattern
        match = re.search(issn_pattern, text)
        
        # If not found, search for the ISSN pattern with an 'x' or 'X' in the last position
        if not match:
            match = re.search(issn_pattern_with_x, text)
        
        # If a match is found, return it
        if match:
            return match.group(0)
        else:
            return "NULL"
    
    def extract_authors(self, text):
        # Find the position of 'et al' in the text
        etal_match = re.search(r'\b(et al)\b', text, re.IGNORECASE)
        
        if etal_match:
            # Find the start and end positions of 'et al'
            etal_start = etal_match.start()
            
            # Text up to 'et al'
            pre_text = text[:etal_start].strip()
            
            # Check for the nearest numeric or separator before 'et al'
            # Separators include commas, semicolons, colons, and hyphens
            separator_match = re.search(r'[\d,;:-]', pre_text[::-1])
            if separator_match:
                separator_pos = len(pre_text) - separator_match.start()
                author_text = text[separator_pos:etal_start].strip()
            else:
                # If no numeric or separator is found, split the text into words
                words_before_etal = pre_text.split()[-5:]
                author_text = ' '.join(words_before_etal)
            
            return author_text
    
        # If 'et al' is not found, return the first word as the author name
        first_space = text.find(' ')
        if first_space > -1:
            return text[:first_space].strip()
        else:
            return "NULL"
            
    def extract_publication_date(self, text):
        # First, look for a full date in a format like "1 October 1985"
        date_match = re.search(r'\b(\d{1,2})\s+([a-zA-Z]+)\s+(\d{4})\b', text)
        
        if date_match:
            day, month_name, year = date_match.groups()
            day = day.zfill(2)  # Ensure day has two digits
            
            # Replace the month name with its number
            month_replacements =  {
                    'january': '01', 'february': '02', 'march': '03', 'april': '04', 'may': '05', 'june': '06',
                    'july': '07', 'august': '08', 'september': '09', 'october': '10', 'november': '11', 'december': '12',
                    'janvier': '01', 'février': '02', 'fevrier': '02', 'mars': '03', 'avril': '04', 'mai': '05', 'juin': '06',
                    'juillet': '07', 'août': '08', 'aout': '08', 'septembre': '09', 'octobre': '10', 'novembre': '11', 'décembre': '12', 'decembre': '12',
                    'enero': '01', 'febrero': '02', 'marzo': '03', 'abril': '04', 'mayo': '05', 'junio': '06', 'julio': '07',
                    'agosto': '08', 'septiembre': '09', 'setiembre': '09', 'octubre': '10', 'noviembre': '11', 'diciembre': '12',
                    'januar': '01', 'februar': '02', 'märz': '03', 'maerz': '03', 'april': '04', 'mai': '05', 'juni': '06', 'juli': '07',
                    'august': '08', 'september': '09', 'oktober': '10', 'november': '11', 'dezember': '12',
                    'gennaio': '01', 'febbraio': '02', 'marzo': '03', 'aprile': '04', 'maggio': '05', 'giugno': '06', 'luglio': '07',
                    'agosto': '08', 'settembre': '09', 'ottobre': '10', 'novembre': '11', 'dicembre': '12'
                }
            month_number = month_replacements.get(month_name.lower())
            
            if month_number:
                date_str = f"{year}-{month_number}-{day}"
                try:
                    return datetime.strptime(date_str, "%Y-%m-%d").date()
                except ValueError:
                    pass  # If parsing fails, continue to other options
        
        # Fall back to searching for a year if no date match is found
        year_match = re.search(r'\b(19|20)\d{2}\b', text)
        if year_match:
            return datetime.strptime(year_match.group(0) + "-01-01", "%Y-%m-%d").date()
        
        return "NULL"

    def extract_volume(self,text):
        # Search for 'vol' or 'bd' followed by a space
        vol_match = re.search(r'\b(vol|bd) (\S+)', text, re.IGNORECASE)
        
        # If a match is found, return the number following 'vol' or 'bd'
        if vol_match:
            return vol_match.group(2)
        return "NULL"
    
    def extract_issue(self,text):
        # Search for 'no' or 'nr' followed by a space and an issue number
        issue_match = re.search(r'\b(no|nr) (\S+)', text, re.IGNORECASE)
        
        # If a match is found, return the number following 'no' or 'nr'
        if issue_match:
            return issue_match.group(2)
        return "NULL"
    
    def extract_pages(self, text):
        # First, check for 'pages' or 'seiten' followed by a number or page range
        pages_match = re.search(r'\b(pages|seiten) (\S.*)', text, re.IGNORECASE)
        
        if pages_match:
            # Extract text after 'pages' or 'seiten'
            rest = pages_match.group(2).strip()
            
            # Define stop keywords and search for their position in the rest of the text
            stop_keywords = ['xp', 'issn', 'isbn']
            stop_index = min([rest.lower().find(keyword) for keyword in stop_keywords if rest.lower().find(keyword) > -1], default=len(rest))
            
            # Extract up to the first stop keyword or to the next space if no keyword found
            if stop_index < len(rest):
                rest = rest[:stop_index].strip()
            else:
                first_space = rest.find(' ')
                rest = rest[:first_space].strip() if first_space > -1 else rest
            
            # Check for page range in the form 'number-number'
            page_range_match = re.search(r'(\d+-\d+)', rest)
            if page_range_match:
                return page_range_match.group(0).strip()
            else:
                return rest  # If no range is found, return the extracted pages or single number
        
        # If no 'pages' or 'seiten' keyword is found, look directly for page ranges
        page_range_match = re.search(r'\b\d+-\d+\b', text)
        if page_range_match:
            return page_range_match.group(0)
        
        return "NULL"

    def extract_doi(self,text):
        # Search for 'doi' followed by the DOI content
        doi_match = re.search(r'\bdoi\s*:\s*(\S+)', text, re.IGNORECASE)
        
        if not doi_match:
            # If no exact match with 'doi:', try to find 'doi' followed by non-space characters
            doi_match = re.search(r'\bdoi\s+(\S+)', text, re.IGNORECASE)
            
        # If a match is found, return the captured DOI content
        if doi_match:
            doi = doi_match.group(1).strip()
            # Stop at the first space after the DOI if present
            space_index = doi.find(' ')
            return doi[:space_index] if space_index > -1 else doi
        
        return "NULL"

    def extract_isbn(self,text):
        """
        Function to extract an ISBN from a given text based on information about ISBN from: https://en.wikipedia.org/wiki/ISBN
        """
        text_lower = text.lower()
        
        # Search for "isbn" in the text
        isbn_pos = text_lower.find("isbn")
        
        if isbn_pos > -1:
            # Extract text following "isbn"
            isbn_text = text_lower[isbn_pos + 4:].strip()
            
            # Extract up to the next space or invalid character
            isbn_match = re.match(r'[\d\- xX]+', isbn_text)
            
            if isbn_match:
                isbn_cleaned = isbn_match.group(0).replace(' ', '').replace('-', '')
                
                # Convert 'x' to uppercase if it's the last character
                if isbn_cleaned[-1].lower() == 'x':
                    isbn_cleaned = isbn_cleaned[:-1] + 'X'
                    
                # Validate ISBN-13
                if len(isbn_cleaned) == 13 and isbn_cleaned.isdigit():
                    return isbn_cleaned
                # Validate ISBN-10
                elif len(isbn_cleaned) == 10 and isbn_cleaned[:-1].isdigit() and isbn_cleaned[-1] in '0123456789X':
                    return isbn_cleaned
        
        # If "isbn" is not found, search for an ISBN-like pattern
        isbn_pattern13 = r'\b\d[\d\- ]{11,16}\b'
        isbn_pattern10 = r'\b\d[\d\- ]{9,13}\b'
        
        # Check for ISBN-13 pattern
        isbn_match = re.search(isbn_pattern13, text_lower)
        if isbn_match:
            isbn_cleaned = isbn_match.group(0).replace(' ', '').replace('-', '')
            
            if len(isbn_cleaned) == 13 and isbn_cleaned.isdigit():
                return isbn_cleaned
        
        # Check for ISBN-10 pattern if ISBN-13 is not found
        isbn_match = re.search(isbn_pattern10, text_lower)
        if isbn_match:
            isbn_cleaned = isbn_match.group(0).replace(' ', '').replace('-', '')
            
            # Convert 'x' to uppercase if it's the last character
            if isbn_cleaned[-1].lower() == 'x':
                isbn_cleaned = isbn_cleaned[:-1] + 'X'
                
            if len(isbn_cleaned) == 10 and isbn_cleaned[:-1].isdigit() and isbn_cleaned[-1] in '0123456789X':
                return isbn_cleaned
        
        return "NULL"
    
    def extract_alpha_numeric(self, text):
        # Remove all non-alphanumeric characters
        alpha_numeric_text = re.sub(r'[^a-zA-Z0-9]', '', text)
        
        # Calculate the length of the cleaned string
        cleaned_length = len(alpha_numeric_text)
        
        return alpha_numeric_text, cleaned_length
    
    # Functions to store the meta data in the SQL table:

    def store_extracted_data(self, data, table_name="extracted_bib_items_group_7"):
        try:
            # Establish connection to SQL Server
            connection = db.connect('Driver={SQL Server};'
                                'Server=uvtsql.database.windows.net;'
                                'Database=db3;'
                                'uid=user71;'
                                'pwd=CompEco1234;')
            cursor = connection.cursor()
            
            # Drop the table if it already exists
            drop_query = f"drop table if exists {table_name};"
            cursor.execute(drop_query)
            connection.commit()
            print(f"Table {table_name} dropped successfully (if it existed).")
            
            # Create the new table
            create_query = f"""
            create table {table_name} (
                id int primary key,
                xp_number nvarchar(50),
                issn nvarchar(9),
                authors nvarchar(255),
                publication_date date,
                volume nvarchar(20),
                issue nvarchar(20),
                pages nvarchar(50),
                doi nvarchar(100),
                isbn nvarchar(20),
                alpha_numeric_text nvarchar(4000),
                text_length int
            );
            """
            cursor.execute(create_query)
            connection.commit()
            print(f"Table {table_name} created successfully.")
            
            # Insert data into the new table
            all_iterations = sum(1 for _ in data)
            print("Saving meta data to data base...")
            for record in tqdm(data, total=all_iterations):
                insert_query = f"""
                insert into {table_name} (id, xp_number, issn, authors, publication_date, volume, issue, pages, doi, isbn, alpha_numeric_text, text_length)
                values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """
                cursor.execute(insert_query, (
                    record['id'], record['xp_number'], record['issn'], record['authors'], str(record['publication_date']) if record['publication_date'] != "NULL" else None,
                    record['volume'], record['issue'], record['pages'], record['doi'], record['isbn'],
                    record['alpha_numeric_text'], record['text_length']
                ))
            connection.commit()
            print("Data inserted successfully.")
            
        except Exception as e:
            print(f"Error processing data: {e}")
        finally:
            # Close the cursor and connection
            cursor.close()
            connection.close()

    def process_and_store_data(self, records):
        processed_data = []
        total_iterations = sum(1 for _ in  records.iterrows())
        print("Extracting meta data...")
        for _, record in tqdm(records.iterrows(), total=total_iterations):
            npl_publn_id = record["npl_publn_id"]
            text = record["npl_biblio_cleaned"]

            # Extract various bibliographic items
            xp_number = self.extract_xp_number(text)
            issn = self.extract_issn(text)
            authors = self.extract_authors(text)
            publication_date = self.extract_publication_date(text)
            volume = self.extract_volume(text)
            issue = self.extract_issue(text)
            pages = self.extract_pages(text)
            doi = self.extract_doi(text)
            isbn = self.extract_isbn(text)


            alpha_numeric_text, text_length = self.extract_alpha_numeric(text)

            # Append processed record to the list
            processed_data.append({
                'id': npl_publn_id,
                'xp_number': xp_number,
                'issn': issn,
                'authors': authors,
                'publication_date': publication_date,
                'volume': volume,
                'issue': issue,
                'pages': pages,
                'doi': doi,
                'isbn': isbn,
                'alpha_numeric_text': alpha_numeric_text,
                'text_length': text_length
            })

        # Store in SQL database
        self.store_extracted_data(processed_data)

# Duplicate Identifier class - identify duplicates

class DuplicateIdentifier:
    
    def __init__(self):
        self.cleaned_data = None
        self.similarity_threshold = None

    def get_data(self):
        query = "select * from extracted_bib_items_group_7" # Change sample here as well
        try:
            conn = db.connect('Driver={SQL Server};'
                                'Server=uvtsql.database.windows.net;'
                                'Database=db3;'
                                'uid=user71;'
                                'pwd=CompEco1234;')
            data = pd.read_sql_query(query, conn)
            conn.close()
            print("Data loaded!")
            return data
        except Exception as e:
            print("Error connecting to the data base: ", e)
        
    def jaccard_similarity(self, set1, set2):
        #Calculate Jaccard similarity between two sets.

        if len(set1.union(set2)) == 0:
            return 0
        return len(set1.intersection(set2)) / len(set1.union(set2))
    
    def metadata_completeness(self, record, metadata_fields):
        filled_fields = sum(1 for field in metadata_fields if record[field] != "NULL" and record[field])
        return filled_fields / len(metadata_fields)

    
    def calculate_similarity(self, record1, record2):
        """
        Calculate similarity between two records using Jaccard Index for meta data
        and Levenshtein Distance for alpha-numeric text.
        """
        # Metadata fields to be used for Jaccard similarity
        metadata_fields = ['xp_number', 'issn', 'authors', 'volume', 'issue', 'pages', 'doi', 'isbn']
        
        # Weights for each metadata field, emphasizing the importance of certain fields
        weights = {
            'xp_number': 5,
            'issn': 3,
            'authors': 2,
            'publication_date': 1,
            'volume': 1,
            'issue': 1,
            'pages': 1,
            'doi': 5,
            'isbn': 3
        }
        
        # Calculate Jaccard similarity for metadata and apply weights
        weighted_metadata_similarity = 0
        total_weight = 0
        for field in metadata_fields:
            set1 = set(str(record1[field]).split())
            set2 = set(str(record2[field]).split())
            if set1.intersection(set2) == {"NULL"}:
                similarity = 0
            else:
                similarity = self.jaccard_similarity(set1, set2)
            weighted_metadata_similarity += weights[field] * similarity
            total_weight += weights[field]
        
        # Calculate date similarity for publication dates and apply weight
        try:
            date_diff = abs((datetime.strptime(record1['publication_date'], "%Y-%m-%d") - datetime.strptime(record2['publication_date'], "%Y-%m-%d")).days)
            if date_diff > 365:
                date_similarity = 0
            else:
                date_similarity = 1 - (date_diff / 365)
        except:
            date_similarity = 0
        
        weighted_metadata_similarity += weights['publication_date'] * date_similarity
        total_weight += weights['publication_date']
        
        # Normalize the weighted similarity
        weighted_metadata_similarity /= total_weight
        if weighted_metadata_similarity > 0.6:
            alpha_numeric_similarity = 0.4
        else:
            # Calculate Levenshtein similarity for alpha-numeric text
            alpha_numeric_distance = Levenshtein.distance(record1['alpha_numeric_text'], record2['alpha_numeric_text'])
            # Calculate Levenshtein similarity for alpha-numeric text
            # Normalizing the Levenshtein distance by dividing by the length of the longer string
            # to convert it into a similarity score between 0 and 1. This ensures that the similarity
            # measure is easy to compare regardless of the length of the strings
            max_length = max(len(record1['alpha_numeric_text']), len(record2['alpha_numeric_text']))
            alpha_numeric_similarity = 1 - (alpha_numeric_distance / max_length) if max_length > 0 else 1
            # after this operation 0 means completely different strings and 1 means same strings.
        
            # Calculate metadata completeness
        completeness1 = self.metadata_completeness(record1, metadata_fields)
        completeness2 = self.metadata_completeness(record2, metadata_fields)
        average_completeness = (completeness1 + completeness2) / 2

        # Adjust weights based on completeness
        metadata_weight = average_completeness
        alpha_numeric_weight = 1 - average_completeness

        # Compute overall similarity
        overall_similarity = (
            metadata_weight * weighted_metadata_similarity +
            alpha_numeric_weight * alpha_numeric_similarity
        )

        return overall_similarity
    
# Cluster Identifier class - compares entreis from Patstat table and creates clusters 

class ClusterIdentifier:
    def __init__(self):
        self.data = None
        self.similarity_threshold = 0.4
        self.pairs_above_threshold = []
        self.duplicate_identifier = DuplicateIdentifier()

    def load_data(self):
        self.data = self.duplicate_identifier.get_data()

    def calculate_pairwise_similarities(self):
        # Calculate pairwise similarities for all records
        # Iterate over each pair of records
        # Use tqdm to wrap the itertools.combinations
        total_combinations = sum(1 for _ in itertools.combinations(self.data.to_dict('records'), 2))
        combinations = itertools.combinations(self.data.to_dict('records'), 2)
        for record1, record2 in tqdm(combinations, total=total_combinations):
            similarity = self.duplicate_identifier.calculate_similarity(record1, record2)

            if similarity > self.similarity_threshold:
                self.pairs_above_threshold.append((record1['id'], record2['id'], similarity))

        print(f"Pairs with similarity above {self.similarity_threshold} identified.")

    def build_graph(self):
        # Build a graph from pairs above the similarity threshold
        self.graph = nx.Graph()
        for record1_id, record2_id, similarity in self.pairs_above_threshold:
            if similarity >= self.similarity_threshold:  # Additional check here
                self.graph.add_edge(record1_id, record2_id, weight=similarity)
        print("Graph built from pairs above threshold.")

    def find_maximal_cliques(self):
        # Find all maximal cliques in the graph
        cliques = list(nx.find_cliques(self.graph))
        print(f"Found {len(cliques)} maximal cliques.")
        return cliques

    def find_connected_components(self):
        # Find all connected components in the graph
        components = list(nx.connected_components(self.graph))
        print(f"Found {len(components)} connected components.")
        return components

    def cluster_data(self):
        # Choose a clustering method: maximal cliques or connected components
        clustering_method = "connected_components"  # Change to "maximal_cliques" if needed

        if clustering_method == "maximal_cliques":
            self.clusters = self.find_maximal_cliques()
        elif clustering_method == "connected_components":
            self.clusters = self.find_connected_components()
        else:
            raise ValueError("Invalid clustering method specified.")

        print(f"Number of clusters formed: {len(self.clusters)}")
        return self.clusters
    
    def post_process_clusters(self):
        # Assign records with no duplicates to single record clusters
        all_ids = set(self.data['id'])
        clustered_ids = set(itertools.chain(*self.clusters))
        unclustered_ids = all_ids - clustered_ids

        for unclustered_id in unclustered_ids:
            self.clusters.append([unclustered_id])

        print(f"Added {len(unclustered_ids)} single record clusters.")

    def save_clusters_to_sql(self):
        # Create a DataFrame to store cluster results
        cluster_records = []
        for cluster_num, cluster in enumerate(self.clusters, start=1):
            for npl_publn_id in cluster:
                cluster_records.append({'cluster_id': cluster_num, 'npl_publn_id': npl_publn_id})

        cluster_df = pd.DataFrame(cluster_records)
        try:
            conn = db.connect('Driver={SQL Server};'
                                'Server=uvtsql.database.windows.net;'
                                'Database=db3;'
                                'uid=user71;'
                                'pwd=CompEco1234;')
            cursor = conn.cursor()
            # Drop table if it exists, then create a new one
            cursor.execute('''
                drop table if exists  patstat_clusters_group_7 ;
                create table patstat_clusters_group_7 (
                    npl_publn_id int primary key,
                    cluster_id INT
                )
            ''')
            conn.commit()
            # Insert data into the table
            total_iterations = sum(1 for _ in cluster_df.iterrows())
            print("Saving clusters to data base...")
            for _, row in tqdm(cluster_df.iterrows(), total=total_iterations):
                cursor.execute('''
                    insert into patstat_clusters_group_7 (npl_publn_id, cluster_id)
                    values (?, ?)
                ''', int(row['npl_publn_id']), int(row['cluster_id']))
            conn.commit()
        except Exception as e:
            print("Error saving clusters to the data base: ", e)
        finally:
            conn.close()

class Statistics:

    def __init__(self):
        self.patstat_cluster_group_7 = None
        self.patstat_golden_set = None
    
    def get_all_data(self):
        # Connect to the database and load data into instance variables
        conn = db.connect('Driver={SQL Server};'
                          'Server=uvtsql.database.windows.net;'
                          'Database=db3;'
                          'uid=user71;'
                          'pwd=CompEco1234;')
        query_patstat_cluster_group_7 = "SELECT * FROM patstat_clusters_group_7"
        query_patstat_golden = "SELECT * FROM patstat_golden_set"
        self.patstat_cluster_group_7 = pd.read_sql_query(query_patstat_cluster_group_7, conn)
        self.patstat_golden_set = pd.read_sql_query(query_patstat_golden, conn)
        print("Data loaded!")
        conn.close()
        
    def Performance_table(self):
        # Use instance variables loaded by get_all_data
        group_clusters_id = pd.merge(self.patstat_cluster_group_7, self.patstat_golden_set, 
                                     left_on='npl_publn_id', right_on='npl_publn_id', how='left')
        group_clusters_id = group_clusters_id.rename(columns={'cluster_id_x': 'cluster_id'})
        
        # Count number of elements in golden set and group 7
        golden_counts = self.patstat_golden_set.groupby('cluster_id').size().reset_index(name='Counts_golden')
        group7_counts = group_clusters_id.groupby('cluster_id').size().reset_index(name='Counts_group7')
        
        # Joint counts between our clusters and the golden set
        joint_counts = group_clusters_id.groupby('cluster_id').size().reset_index(name='Counts_joint')
        
        # Merging counts into a final table
        joint_gold = joint_counts.merge(golden_counts[['cluster_id', 'Counts_golden']], on='cluster_id', how='left')
        cluster_pairs = joint_gold.merge(group7_counts[['cluster_id', 'Counts_group7']], left_on='cluster_id', right_on='cluster_id', how='left')
        
        # Calculating performance metrics
        cluster_pairs['Precision'] = (cluster_pairs['Counts_joint']) / (cluster_pairs['Counts_group7'])
        cluster_pairs['Recall'] = (cluster_pairs['Counts_joint']) / (cluster_pairs['Counts_golden'])
        cluster_pairs['F1_score'] = 2 * ((cluster_pairs['Precision']) * (cluster_pairs['Recall'])) / ((cluster_pairs['Precision']) + (cluster_pairs['Recall']))

        # Some Recall values are not able to be calculated, set them to 0
        cluster_pairs['Recall'] = cluster_pairs['Recall'].fillna(0)
        cluster_pairs['F1_score'] = cluster_pairs['F1_score'].fillna(0)
        cluster_pairs['Counts_joint'] = cluster_pairs['Counts_joint'].fillna(0).astype(int)
        cluster_pairs['Counts_golden'] = cluster_pairs['Counts_golden'].fillna(0).astype(int)
        cluster_pairs['Counts_group7'] = cluster_pairs['Counts_group7'].fillna(0).astype(int)

        cluster_pairs['cluster_number'] = range(1, len(cluster_pairs) + 1)


        
        # Sorting the result based on F1 score
        cluster_pairs_F1sort = cluster_pairs.sort_values(by=['F1_score'])
        
        return cluster_pairs_F1sort
    
    def plots(self, cluster_pairs):
        # This method takes the dataframe of performance and plots graphs of them and prints tables of averages
        
        # Precision mean and median
        print(cluster_pairs[['Precision']].agg(['mean', 'median']))
        
        # Precision plot
        precisions_grouped = cluster_pairs.groupby('cluster_id')['Precision'].idxmax().reset_index() 
        max_precisions = cluster_pairs.loc[precisions_grouped['Precision']]
        max_precisions_sorted = max_precisions.sort_values(by='Precision', ascending=False).reset_index(drop=True)
        
        plt.plot(max_precisions_sorted.index, max_precisions_sorted['Precision'])
        plt.xlabel('Our Cluster number (on best golden cluster)')
        plt.ylabel('Precision')
        plt.title('Precision of our clusters on the (best) golden clusters')
        plt.show()
        
        # Recall mean and median
        print(cluster_pairs[['Recall']].agg(['mean', 'median']))
        
        # Recall plot
        recall_grouped = cluster_pairs.groupby('cluster_id')['Recall'].idxmax().reset_index()
        max_recall = cluster_pairs.loc[recall_grouped['Recall']]
        max_recall_sorted = max_recall.sort_values(by='Recall', ascending=False).reset_index(drop=True)
        
        plt.plot(max_recall_sorted.index, max_recall_sorted['Recall'])
        plt.xlabel('Golden clusters with the best recall')
        plt.ylabel('Recall')
        plt.title('Recall of the golden clusters by our best clusters')
        plt.show()
        
        # F1-score mean and median for all clusters
        print(cluster_pairs[['F1_score']].agg(['mean', 'median']))
        
        # Top 100 F1 scores
        cluster_pairs_F1top100 = cluster_pairs.nlargest(100, 'F1_score')
        print(cluster_pairs_F1top100[['F1_score']].agg(['mean', 'median']))
        
        # Specific clusters to analyze
        good_cluster = cluster_pairs[cluster_pairs['cluster_id'] == 10]
        bad_cluster = cluster_pairs[cluster_pairs['cluster_id'] == 117]
        perfect_cluster = cluster_pairs[cluster_pairs['cluster_id'] == 84]
        print(good_cluster)
        print(bad_cluster)
        print(perfect_cluster)
        
        # F1-score plot
        F1_grouped = cluster_pairs.groupby('cluster_id')['F1_score'].idxmax().reset_index()
        max_F1 = cluster_pairs.loc[F1_grouped['F1_score']]
        max_F1_sorted = max_F1.sort_values(by='F1_score', ascending=False).reset_index(drop=True)
        
        plt.plot(max_F1_sorted.index, max_F1_sorted['F1_score'])
        plt.xlabel('Golden clusters with the best F1 score')
        plt.ylabel('F1 score')
        plt.title('F1 score of the golden clusters obtained by our best clusters')
        plt.show()
    
    def upload_performance(self, cluster_pairs):
        # This method loads the table with the F1 performance back into SQL
        
        conn = db.connect('Driver={SQL Server};'
                          'Server=uvtsql.database.windows.net;'
                          'Database=db3;'
                          'uid=user71;'
                          'pwd=CompEco1234;')
        
        # Drop and recreate the table
        query1 = "IF OBJECT_ID('group7_performance') IS NOT NULL DROP TABLE group7_performance;"
        conn.execute(query1)
        conn.commit()
        
        query2 = """
        CREATE TABLE group7_performance (
            cluster_number VARCHAR(255),
            cluster_id VARCHAR(255),
            joint_counts VARCHAR(255),
            gold_counts VARCHAR(255),
            our_counts VARCHAR(255),
            Precision VARCHAR(255),
            Recall VARCHAR(255),
            F1_score VARCHAR(255)
        );
        """
        conn.execute(query2)
        conn.commit()
    
        # Insert data into the table
        for index, row in cluster_pairs.iterrows():
            st = """
            INSERT INTO group7_performance 
            (cluster_number, cluster_id, joint_counts, gold_counts, our_counts, Precision, Recall, F1_score)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """
            conn.execute(st, (row['cluster_number'], row['cluster_id'], row['Counts_joint'], 
                              row['Counts_golden'], row['Counts_group7'], 
                              row['Precision'], row['Recall'], row['F1_score']))
            conn.commit()
        
        conn.close()


class PerformanceAnalysis:
    # Class to calculate performance statistics using the following approach:
    # For both true and predicted clusters, we generate all possible pairs of npl_publn_id within each cluster.
    # For each predicted cluster, compare its pairs of npl_publn_id values to those generated from the true clusters.
    # We count the matches:
    # TP - Pairs present in both predicted and true clusters.
    # FP - Pairs present in predicted clusters but missing from true clusters.
    # FN - Pairs present in true clusters but missing from predicted clusters.
    # Then based on those values we calculate Precision, Recall and F1 score for each predicted cluster and average F1 score.
    def __init__(self):
        try:
            conn = db.connect('Driver={SQL Server};'
                        'Server=uvtsql.database.windows.net;'
                        'Database=db3;'
                        'uid=user71;'
                        'pwd=CompEco1234;')
            true_clusters_query = """
            SELECT npl_publn_id, cluster_id
            FROM patstat_golden_set
            """
            self.patstat_golden_set = pd.read_sql(true_clusters_query, conn)

            predicted_clusters_query = """
            SELECT npl_publn_id, cluster_id
            FROM patstat_clusters_group_7
            """
            self.patstat_clusters_group_7 = pd.read_sql(predicted_clusters_query, conn)
            conn.close()
        except:
            print("Error collecting the data from the data base!")

    def calculate_tp_fp_fn(self):
        # Create a dictionary of true pairs for each true cluster
        true_cluster_pairs = (
            self.patstat_golden_set.groupby('cluster_id')['npl_publn_id']
            .apply(lambda x: set(itertools.combinations(sorted(x), 2)))  # Generate all pairs within each true cluster
        )
        self.all_true_pairs = set().union(*true_cluster_pairs)
        # Initialize dictionaries to hold true positives and false positives for each predicted cluster
        self.true_positives_per_predicted_cluster = {}
        self.false_positives_per_predicted_cluster = {}
        self.false_negatives_per_predicted_cluster = {}

        # Calculate true positives and false positives for each predicted cluster
        total = sum(1 for _ in self.patstat_clusters_group_7.groupby('cluster_id')['npl_publn_id']) 
        print("Calculating tp, fp, fn...")
        for predicted_cluster, npl_publn_ids in tqdm(self.patstat_clusters_group_7.groupby('cluster_id')['npl_publn_id'], total=total):
            # Generate pairs within the predicted cluster
            predicted_pairs = set(itertools.combinations(sorted(npl_publn_ids), 2))
            
            true_positive_count = 0
            false_positive_count = 0
            
            # Check each predicted pair
            for pair in predicted_pairs:
                is_true_positive = False
                # Check if the pair exists in the same true cluster
                for true_cluster_pair_set in true_cluster_pairs:
                    if pair in true_cluster_pair_set:
                        true_positive_count += 1
                        is_true_positive = True
                        break
                
                # If the pair is not a true positive, it is a false positive
                if not is_true_positive:
                    false_positive_count += 1
            
            # Calculate false negatives: True pairs that are missing from the predicted pairs
            false_negative_count = len(self.all_true_pairs.difference(predicted_pairs))
            
            # Store the true positives, false positives, and false negatives count for this predicted cluster
            self.true_positives_per_predicted_cluster[predicted_cluster] = true_positive_count
            self.false_positives_per_predicted_cluster[predicted_cluster] = false_positive_count
            self.false_negatives_per_predicted_cluster[predicted_cluster] = false_negative_count
        
    def calculate_precision_recall_f1(self):
        self.precision_per_predicted_cluster = {}
        self.recall_per_predicted_cluster = {}
        self.f1_score_per_predicted_cluster = {}
        # Step 5: Calculate precision, recall, and F1 score for each predicted cluster
        for predicted_cluster in self.true_positives_per_predicted_cluster.keys():
            tp = self.true_positives_per_predicted_cluster[predicted_cluster]
            fp = self.false_positives_per_predicted_cluster[predicted_cluster]
            fn = self.false_negatives_per_predicted_cluster[predicted_cluster]
            
            # Precision: tp / (tp + fp)
            if tp + fp > 0:
                precision = tp / (tp + fp)
            else:
                precision = 0.0
            
            # Recall: tp / (tp + fn)
            if tp + fn > 0:
                recall = tp / (tp + fn)
            else:
                recall = 0.0
            
            # F1 Score: 2 * (precision * recall) / (precision + recall)
            if precision + recall > 0:
                f1_score = 2 * (precision * recall) / (precision + recall)
            else:
                f1_score = 0.0  # Handle case where precision + recall is 0 (both are zero)
            
            # Store the precision, recall, and F1 score for this predicted cluster
            self.precision_per_predicted_cluster[predicted_cluster] = precision
            self.recall_per_predicted_cluster[predicted_cluster] = recall
            self.f1_score_per_predicted_cluster[predicted_cluster] = f1_score

    def plotting(self):
        # Convert dictionaries to lists of values for plotting
        predicted_clusters = list(self.precision_per_predicted_cluster.keys())
        precision_values = list(self.precision_per_predicted_cluster.values())
        recall_values = list(self.recall_per_predicted_cluster.values())
        f1_values = list(self.f1_score_per_predicted_cluster.values())

        # Plot Precision
        plt.figure(figsize=(10, 6))
        plt.bar(predicted_clusters, precision_values, color='blue', alpha=0.7)
        plt.xlabel('Predicted Cluster ID')
        plt.ylabel('Precision')
        plt.title('Precision per Predicted Cluster')
        plt.xticks(rotation=90)
        plt.tight_layout()
        plt.show()

        # Plot Recall
        plt.figure(figsize=(10, 6))
        plt.bar(predicted_clusters, recall_values, color='green', alpha=0.7)
        plt.xlabel('Predicted Cluster ID')
        plt.ylabel('Recall')
        plt.title('Recall per Predicted Cluster')
        plt.xticks(rotation=90)
        plt.tight_layout()
        plt.show()

        # Plot F1 Score
        plt.figure(figsize=(10, 6))
        plt.bar(predicted_clusters, f1_values, color='red', alpha=0.7)
        plt.xlabel('Predicted Cluster ID')
        plt.ylabel('F1 Score')
        plt.title('F1 Score per Predicted Cluster')
        plt.xticks(rotation=90)
        plt.tight_layout()
        plt.show()
        
    def get_average_f1(self):
        # Calculate the average F1 score over all clusters
        average_f1_score = np.mean(list(self.f1_score_per_predicted_cluster.values()))
        print(f"Average F1 Score: {average_f1_score:.4f}")

if __name__ == "__main__": 
    """
    data_preprocessor  = DataPreprocessor()
    data_preprocessor.connect_to_db()
    data_preprocessor.preprocess_data()
    data_preprocessor.process_and_store_data(data_preprocessor.cleaned_data)

    cluster_identifier = ClusterIdentifier()
    print("Loading data")
    cluster_identifier.load_data()
    print("Data Loaded")
    print("Calculating pairwise similarities...")
    cluster_identifier.calculate_pairwise_similarities()
    print("Calculating pairwise similarities - done")
    print("Building clusters")
    cluster_identifier.build_graph()
    clusters = cluster_identifier.cluster_data()
    cluster_identifier.post_process_clusters()
    print("Building clusters - done")
    cluster_identifier.save_clusters_to_sql()
    print("Clusters saved to SQL")"""

    performance = PerformanceAnalysis()
    performance.calculate_tp_fp_fn()
    performance.calculate_precision_recall_f1()
    performance.plotting()
    performance.get_average_f1()