# Using TonicNet artificial chorales to generate new compositions

The original TonicNet work can be found here: https://github.com/omarperacha/TonicNet

This repo contains a collection of codes to do two things:
1.  Generate a large collection of synthetic Bach chorales, and evaluate them across a set of metrics. See the notebook TonicNet_Synthetic_Chorale_refactored.ipynb
  
2.  Generate complete pieces from some cherry-picked chorales with a variety of orchestrations. See the notebook TonicNet_Csound_Arpeggios.ipynb
  
Examples of the results can be heard here: http://ripnread.com/sample-page/blog/

To realize the pieces, you will need to install csound, and obtain the instrument samples from another of my repos: Diamond_Music here: https://github.com/prentrodgers/Diamond_Music

To run the generation notebook, you will need some of the modules from the original TonicNet repo.
<code>
# These are pulled from the TonicNet github: 
from eval.sample import sample_TonicNet_random
from eval.utils import plot_loss_acc_curves, indices_to_stream, smooth_rhythm
</code>
