

import numpy as np
import scipy.optimize as optimize
import scipy.integrate as integrate
import scipy.stats as stats
import matplotlib as mp
import matplotlib.pyplot as plt

"""
Enter your code for the questions below in the indicated places
"""

"""
Pandora's box problem

Exercise 1a)
"""
def a_1(A, P, y):
    exp_vect = np.matmul(A, np.transpose(P))
    y_reduced_exp = exp_vect - y
    non_neg_comb_matrix = np.clip(y_reduced_exp, 0, None)
    result = np.diagonal(non_neg_comb_matrix)
    return result

"""
Exercise 1b)
"""
#using min_square_roots wouldve returned an array without any loops, but had to use brentq: hence, we used the "map"funtion and applied it as a loop substitute.
#used a bracket starting at [c-max(Xi)] for any specific distribution since, if the E(Xi) is "to small to reach c" even when y=0, we will need a negative y, of the size that is missing between E(Xi) and c.Hence, worst case scenario, -(max(Xi)-c)=-max(Xi)+c
 #used a bracket ending at max Xi because the root y can be at most the maximum value that Xi can take; if it's equal to the max or larger, it corresponds to the c which is 0 

def equation_solver(y, A, P, c, x):
    return (a_1(A, P, y) - c)[x]
def b_1(A, P, c):
    
    def solve_single_equation(i):
        max_Ai = np.max(A[i])
        return optimize.root_scalar(equation_solver, method='brentq', bracket=[-max_Ai+c[i],max_Ai], args=(A, P, c, i)).root

    result = list(map(solve_single_equation, range(len(c))))
    return result
"""
Exercise 1c)
"""
'getting pdf of the inputed distribution distribution'
def  pdf(F,x):
    return F.pdf(x)

'definig the full function thats has to be integrated' 
def function(x,y,f):
    return max(x-y,0)*pdf(f,x)

'integral of the function and subtracting c so it is =0  we can determine y solving the question'
def integral(y,c,f):
    'as pdfs are not generally the same for whole R we need to take a look where pdf is a function and not 0 there is no point integrating multiplication with 0'
    lower_bound , upper_bound=f.support()
    'these bounds are chosen usong the precent-point function and inverse survival function bc we are konw that over this bounds there is a 0.1% chance that the pdf has an actual value if this step is excluded results ar nonsense'
    if np.isinf(lower_bound):
        lower_bound=f.ppf(0.001)
    if np.isinf(upper_bound):
        upper_bound=f.isf(0.001)
        'integrating with respect to x took from scipy.integrat forum'
    result= integrate.quad(lambda x: function(x,y,f), lower_bound, upper_bound)
    integratedval=result[0]-c
   
    return integratedval

'aplying brentq method to determine y as instructed in the exercise'
def maximization(f,c):
    'since we are working with integration of a pdf which is essentally cdf we can use the functions of precent-point function and inverse survival function to get genral bounds to find y '
    'these bounds seem to work good if the c is not more than 1500 times larger than the mean of the distribution, and the mean and std are in sensable proportions, so i would say that it is a success with choosing them '
    lower_boundf = f.ppf(0.001)-c  
    upper_boundf = f.isf(0.001)+c 
    'solving the equations respect to y using brents method as instructed'
    result=optimize.root_scalar(lambda y: integral(y,c,f), method='brentq',bracket=[lower_boundf, upper_boundf])
    return result.root
"""
Exercise 1d)
"""
#Input
mu = np.array([4,6,2,7,10])
sigma = np.array([1,2,5,7,11])
c = np.array([1,1,1,1,1])
'using combination of lamda and map so we can efficiently get the values for ech mean , standartdeviation and cost, this function should work for any  normal distribution '
solutions = map(lambda mean_val, std_val, c_val: maximization(stats.norm(loc=mean_val, scale=std_val), c_val), mu, sigma, c)
'if the solutions ar not converted to a list it has no readable value'
print(list(solutions))
"""
Exercise 1e)
"""
'for this exercise I just did the steps given in the exercise'
def weitzalg(reservation_price , cost , reward):
    'combining the 3 inputs for each box so we can implament the caculations, and compere the boxes '
    all_boxes=np.array([reservation_price,cost, reward]).T
    'sorting boxes by reservation price this is step ii) of weitzmans'
    'selescting all rows but only first column which is reservation price so we can sort by it'
    'index 0 smallest reservation price so need to reverse so we can open the highest reservation price first'
    'this step is allso needed for later step where i extract the index of the chosen box'
    boxes_sorted_indeces=np.argsort(all_boxes[:, 0], axis=0)[::-1]
    
    'now sort the actual boxes by reservation price using the indeces'
    boxes_sorted=all_boxes[boxes_sorted_indeces]
    'finding boxes where reward is higher equal the reservation price to see if any boxes meet the criterion iii) of weitzmans '
    index_condition = boxes_sorted[:,2] >= boxes_sorted[:,0]
    'geting indeces of boxes which have reward higher equal to reservation price'
    indexes = np.where(index_condition)[0]
    'chekling if any of the boxes meet the criterion'
    if len(indexes) == 0:      
        'if no box meets the criterion we open all boxes and we caculate the cost of it and pick the box with highest reward'
        'caculating the utility of these actions'
        utility = max(boxes_sorted[:,2]) - sum(boxes_sorted[:,1])
        'index is just the index of a box with highest reward becaus if we open all boxes we will pick box with highest reward'
        index = np.argmax(all_boxes[:,2])
        return utility,index
    else:
        'getting the cost of opining a box at each step so we know how much is to open first n boxes in the actual opening order'
        cost_step=np.cumsum(boxes_sorted[:,1])
        'geting reward at a step so we can easaly acces the rewards of each box in the opening order'
        rewards_step=boxes_sorted[:,2]
        'selecting the box which meets the conddition iii) fisrt appers when boxes ar opend in decreasing order of reservation price '
        box_index=indexes[0]
        'selecting the box with hidhest reward from all of the opened boxes'
        
        reward_final=max(rewards_step[:box_index+1])
   
        
        'the cost of openig the boxes untll the condition are met'                 
        cost_final=cost_step[box_index]
        'caculating utility'
        utility=reward_final-cost_final
        'getting the index of chosen reward from original matrix'
        reward_final_index=np.argmax(rewards_step[:box_index+1])
        higest_reaward_seen_index=boxes_sorted_indeces[reward_final_index]
        return utility, higest_reaward_seen_index
"""
Exercise 1f)
"""

#Input
A = np.array([[1,5,6,7],
              [2,4,6,8],
              [1,4,6,7],
              [2,5,7,8],
              [1,2,3,10]])

P = np.array([[0.1,0.1,0.4,0.4],
              [0.1,0.3,0.3,0.3],
              [0.1,0.3,0.3,0.3],
              [0.2,0.2,0.2,0.2],
              [0.4,0.4,0.1,0.1]])
c = np.array([1,3,2,4,1])
v = np.array([5,1,4,7,10])

def f(A,P,c,v):
    rezp=b_1(A,P,c)
    result=weitzalg(rezp,c,v)
    return result

print(f(A,P,c,v))
"""
Exercise 1g)
"""
def g(p):
    # Generating a random value
    pgen = np.random.rand()
    # Creating a CDF matrix out of PDF matrix
    cdf = np.cumsum(p, axis=1)

    # Check if the matrix is a distribution matrix
    #usign subtraction instead of equality since then we can controll for error.
    if np.any(np.abs(cdf[:,-1] - 1) > 0.1):
        print(cdf[:,-1])
        raise Exception("Given matrix is not a distribution matrix.")

    # Find the place where pgen is between two entries
    genfromdist = np.argmax(pgen <= cdf, axis=1) + 1

    return genfromdist

"""
Exercise 1h)
"""

#Input
P= np.array([[0.1,0.1,0.6,0.1,0.1],
             [0.1,0.2,0.4,0.2,0.1],
             [0.3,0.1,0.2,0.1,0.3],
             [0.2,0.1,0.1,0.1,0.5]])
c = np.array([1,2,1,2])

def h(P,c):
    #creating matrix A
    col=np.shape(P)[1]
    support=np.arange(1,col+1)
    A = np.tile(support, (np.shape(P)[0], 1))
    #Getting reservation prices from b
    rezp=b_1(A,P,c)
    #Getting values.
    T=100000
    utility=0
    for i in range(0,T):
        v=g(P)
        utility+=weitzalg(rezp,c,v)[0]
    meanutility=utility/T
    return meanutility
print(h(P,c))
"""
Sparse vector approximation

Exercise 2i)
"""
def return_column_index(x,size=1):
    #calculates the CDF of x
    cdf = np.cumsum(x) #calculates the CDF of x
    #getting a random number between 0 and 1 using Uniform Distribution (0,1)
    random_no = np.random.rand(size) #getting size (size is some number; by default 1) random numbers between 0 and 1 using Uniform Distribution (0,1)
    data=[random_no,cdf, np.argmax(cdf >= random_no[:,None], axis=1)]
    #data is a list of the random_no, cdf and the column index which is the maximum column index that meets the condition of the cdf is >= the random_no

    column_index=data[2] #returning the 3rd value in the list
    return column_index
"""
Exercise 2j)
"""
def return_xk(ck,n):
    k=np.size(ck) #creating a variable k which is the number of realisations of X
    matrix0=np.zeros((n,k)) #creating a 0 matrix with a size n (number of columns) by the size of ck (number of realisations of X)
    rrange=np.arange(k) #creating a vector entries 0,1...,k
    matrix0[ck,rrange]=1 #creating vectors e^c_1 etc by creating unit vectors in according to the formula (boolean)
    cumsum=np.cumsum(matrix0,axis=1) #calculating of a cumulative sum per row. the results are stored in an array
    xk=(cumsum/np.arange(1,k+1)) #returning the x^k according to the formula (7)
    return xk
"""
Exercise 2k)
"""
def LKmatrix_difference(x,y,A,K,L):
    
    # First, we extract the dimensions of both x and y.
    m=np.size(y) #m is the size of row vector
    n=np.size(x) #n is the size of the column vector
    
    rows=return_column_index(y,L) #creating a vector of L realisations (its size) of the random variable Y (sample of row indices)
    columns=return_column_index(x,K) #creating a vector of K realisations (its size) of the random variable X (sample of column indices)
    
    yl = np.transpose(return_xk(rows,m)) #creating y^(l)'s using the function which creates them and is defined in part j (7) (must be transposed as a row vector)
    xk = return_xk(columns,n) #creating x^(k)'s using the function which creates them and is defined in part j (7)
    
    yAx= y@A@x #vector matrix multiplication (first part of (6))
    ylAxk=yl@A@xk #vector matrix multiplcation (second part of (6))

    difference = abs(yAx-ylAxk) #6
    return difference
"""
Exercise 2l)
"""
n=100 #assigning values
m=1000 #assigning values
K=1000 #assigning values
L=1000 #assigning values
x=np.ones(n) #creating a vector of ones size 100
x=x/n #dividing the vector of ones by n=100
y=x#y is equal to x
A=np.random.rand(n,n) #creating a random matrix with entries [0,1] size n by n
difference_matrix=LKmatrix_difference(x, y, A, K, L) #applying the function from k in order to get the difference matrix  
q=np.arange(m) #getting 0,1,...,1000
diagonal=np.diag(difference_matrix) #difference in formula (6) for l=k=q is the values of the diagonal of the difference matrix 
plt.scatter(q,diagonal) #scatter plotting the difference (diagonal values) for q
plt.show() #showing the scatter plot
