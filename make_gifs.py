import os,glob


files = sorted(glob.glob('screenshotsv1/*.png'))
# 250/250
cmd = 'convert -set delay 25 -gravity Center -crop 256x256+0+0 +repage -dispose Background -loop 0 -scale 80%% %s figures/version1_seq.gif'%(' '.join(files))
print(cmd)
os.system(cmd)


files = sorted(glob.glob('screenshotsv2/*.png'))
# 250/250
cmd = 'convert -set delay 25 -gravity Center -crop 256x256+0+0 +repage -dispose Background -loop 0 -scale 80%% %s figures/version2_seq.gif'%(' '.join(files))
print(cmd)
os.system(cmd)
