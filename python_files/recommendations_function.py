#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd
import numpy as np
from scipy.sparse import csr_matrix
from sklearn.neighbors import NearestNeighbors
import matplotlib.pyplot as plt
import seaborn as sns


# In[2]:


movies = pd.read_csv("data/movies.csv")


# In[3]:


links = pd.read_csv("data/links.csv", dtype={'imdbId': object})


# In[4]:


movies = movies.merge(links, on ='movieId', how ='left')


# In[5]:


movies = movies.drop(columns = ['tmdbId'])


# In[6]:


movies['imdbId'] = 'tt' + movies['imdbId'].astype(str)


# In[7]:


movies.rename(columns = {'movieId' : 'movieID', 'imdbId': 'imdbID'}, inplace=True)


# In[8]:


ratings = pd.read_csv("data/ratings.csv")


# In[9]:


ratings.rename(columns = {'movieId' : 'movieID', 'userId': 'userID'}, inplace=True)


# In[10]:


ratings = ratings.drop(columns = ['timestamp'])


# In[11]:


data = ratings.pivot_table(index = 'movieID',columns = 'userID',values = 'rating', fill_value = 0)


# In[12]:


movie_votes = ratings.groupby('movieID')['rating'].agg('count')


# In[13]:


user_votes = ratings.groupby('userID')['rating'].agg('count')


# In[14]:


data = data.loc[movie_votes[movie_votes > 10].index,:]


# In[15]:


data = data.loc[:,user_votes[user_votes > 10].index]


# In[16]:


csr_data = csr_matrix(data.values)
data.reset_index(inplace=True)


# In[17]:


csr_data


# In[18]:


knn = NearestNeighbors(metric='euclidean', algorithm='auto', n_neighbors=20, n_jobs=-1)


# In[19]:


knn.fit(csr_data)


# In[20]:


def create_recommendations(movie_name):
    movies_recommend = 10
    movies_list = movies[movies['title'] == movie_name]
    if len(movies_list):
        movie_idx= movies_list.iloc[0]['movieID']
        movie_idx = data[data['movieID'] == movie_idx].index[0]
        distances , indices = knn.kneighbors(csr_data[movie_idx], n_neighbors = movies_recommend + 1)
        rec_movie_indices = sorted(list(zip(indices.squeeze().tolist(),distances.squeeze().tolist())), key = lambda x: x[1])[:0:-1]
        recommend_frame = []
        for val in rec_movie_indices:
            movie_idx = data.iloc[val[0]]['movieID']
            idx = movies[movies['movieID'] == movie_idx].index
            recommend_frame.append({'imdbID':movies.iloc[idx]['imdbID'].values[0], 'Title':movies.iloc[idx]['title'].values[0], 'Distance':val[1]})
        results_table = pd.DataFrame(recommend_frame, index = range(1, movies_recommend + 1))
        return results_table
    else:
        return "Lack of recommendations. Please, check your movie title"
