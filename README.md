# Using TonicNet artificial chorales to generate new compositions

The original TonicNet work can be found here: https://github.com/omarperacha/TonicNet

This repo contains a collection of notebooks to do several things:
1.  Generate a large collection of synthetic Bach chorales using the TonicNet model. Set the starting and ending number of the chorales in the line: 

<code>
for synth_chorale in range(5000, 5001): # change 5000 to the starting number and 5001 to the ending number
</code>
See the notebook TonicNet_Synthetic_Chorale_Manufacture.ipynb.
To run the generation notebook, you will need some of the modules from the original TonicNet repo in the eval directory: https://github.com/omarperacha/TonicNet/tree/master/eval
<code>
The model: TonicNet_epoch-58_loss-0.322_acc-90.745.pt
# These are pulled from the TonicNet github: 
from eval.sample import sample_TonicNet_random
from eval.utils import plot_loss_acc_curves, indices_to_stream, smooth_rhythm
</code>

2.  Evaluate a large collection of synthetic Bach chorales, and evaluate them across a set of metrics. See the notebook TonicNet_Synthetic_Chorale_trimmed.ipynb. It takes about a second to evaluate one file. I ran it against 4900 synthetic chorales and saved the results as metrics.npy. That took about 20 minutes. 

3.  Generate complete pieces from one chorale. See the notebook TonicNet_Csound_Arpeggios.ipynb
  
Examples of the results can be heard here: http://ripnread.com/sample-page/blog/

To realize the pieces, you will need to install csound, and obtain the instrument samples from another of my repos: Diamond_Music here: https://github.com/prentrodgers/Diamond_Music


