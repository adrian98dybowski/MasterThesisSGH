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


movies = pd.read_csv("movies.csv")


# In[3]:


links = pd.read_csv("links.csv")


# In[4]:


movies = movies.merge(links, on ='movieId', how ='left')


# In[5]:


movies = movies.drop(columns = ['tmdbId'])


# In[6]:


movies['imdbId'] = 'tt' + movies['imdbId'].astype(str)


# In[7]:


movies.rename(columns = {'movieId' : 'movieID', 'imdbId': 'imdbID'}, inplace=True)


# In[8]:


ratings = pd.read_csv("ratings.csv")


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


plt.scatter(movie_votes.index, movie_votes, color = 'green')
plt.axhline(y = 10,color = 'red')
plt.xlabel('Movie ID')
plt.ylabel('Number of users votes on the movie')
plt.show()


# In[15]:


plt.scatter(user_votes.index, user_votes, color = 'yellow')
plt.axhline(y = 20, color = 'blue')
plt.xlabel('User ID')
plt.ylabel('Number of user votes')
plt.show()


# In[16]:


movie_irrelevant = movie_votes[movie_votes < 10]


# In[17]:


movie_drop = movie_irrelevant.size/movie_votes.size


# In[18]:


movie_drop


# In[19]:


movie_weak = movie_votes[movie_votes == 1]


# In[20]:


movie_weak.size


# In[21]:


movie_drop1 = movie_weak.size/movie_votes.size


# In[22]:


movie_drop1


# In[23]:


user_irrelevant = user_votes[user_votes < 20]


# In[24]:


user_irrelevant.size


# In[25]:


user_drop = user_irrelevant.size/user_votes.size


# In[26]:


user_drop


# In[27]:


data = data.loc[movie_votes[movie_votes >= 10].index,:]


# In[28]:


data = data.loc[:,user_votes[user_votes >= 20].index]


# In[29]:


csr_data = csr_matrix(data.values)
data.reset_index(inplace=True)


# In[30]:


csr_data


# In[31]:


knn = NearestNeighbors(n_neighbors=11, metric='cosine', algorithm='auto', n_jobs=-1)


# In[32]:


knn.fit(csr_data)


# In[33]:


def create_recommendations(movie_name):
    movies_recommend = 10
    movies_list = movies[movies['title'] == movie_name]
    if len(movies_list):
        movie_idx= movies_list.iloc[0]['movieID']
        movie_idx = data[data['movieID'] == movie_idx].index[0]
        distances , indices = knn.kneighbors(csr_data[movie_idx], n_neighbors = movies_recommend + 1)
        rec_movie_indices = sorted(list(zip(indices.squeeze().tolist(),distances.squeeze().tolist())), 
                                   key = lambda x: x[1])[:0:-1]
        recommend_frame = []
        for val in rec_movie_indices:
            movie_idx = data.iloc[val[0]]['movieID']
            idx = movies[movies['movieID'] == movie_idx].index
            recommend_frame.append(
                {'imdbID':movies.iloc[idx]['imdbID'].values[0], 'Title':movies.iloc[idx]['title'].values[0], 
                 'Distance':val[1]})
        results_table = pd.DataFrame(recommend_frame, index = range(1, movies_recommend + 1))
        return results_table
    else:
        return "Lack of recommendations. Please, check your movie title"


# In[34]:


create_recommendations("Lion King, The (1994)")

