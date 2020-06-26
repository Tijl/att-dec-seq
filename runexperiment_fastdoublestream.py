#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Oct 23 10:24:22 2018

@author: tgro5258
"""

from psychopy import core, event, visual, parallel, gui
import random,sys,json,requests,os
from glob import glob

# debug things
debug_testsubject = 1
debug_usedummytriggers = 1
debug_windowedmode = 1
debug_save_screenshots = 1

objectstimuli = sorted(glob('stimuli/*.png'))
letterstimuli = 'ABCDEFGJKLQRTUVY'

if debug_testsubject:
    subjectnr = 0
else:
    # Get subject info
    subject_info = {'Subject number':''}
    if not gui.DlgFromDict(subject_info,title='Enter subject info:').OK:
        print('User hit cancel at subject information')
        exit()
    try:
        subjectnr = int(subject_info['Subject number'])
    except:
        raise

nstimuli = 16
nsequence = 48 #number of sequences per condition (letter vs object 2back)
nrepeats = 2 #repeats per sequence

random.seed(subjectnr)

refreshrate = 60
feedbackduration = .5 - .5/refreshrate
fixationduration = 1 - .5/refreshrate
stimduration = .2 - .5/refreshrate
isiduration = .4 - .5/refreshrate

trigger_stimon = 1
trigger_stimoff = 2
trigger_sequencestart = 3
trigger_duration = 0.010
trigger_port = 0xcff8


webhook_url='https://hooks.slack.com/services/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'

stimnum1 = list(range(nstimuli))
stimnum2 = list(range(nstimuli))

trialstructures = [];
targets = [x%nstimuli for x in range(2*nsequence)]
random.shuffle(targets)
t=-1

for i in range(nsequence):
    random.shuffle(stimnum1)
    random.shuffle(stimnum2)
    stream = []
    for j in range(nrepeats):
        x=[]
        while not x or stream and len(set(stream[-4:]).intersection(set(x[:4]))):
            x = random.sample(range(nstimuli),nstimuli)
        stream+=x
    
    #insert 2backs at two random pos in stream
    istarget=[0 for x in range(len(stream))]
    for j in range(2):
        t+=1
        start = int(0.5*len(stream))+5 if j else 5
        end = len(stream)-5 if j else int(0.5*len(stream))-5
        randpos = random.randint(start,end)
        while any([stream[randpos+x]==targets[t] for x in range(-3,3)]):
            randpos = random.randint(start,end)
        
        stream.insert(randpos-1,targets[t])
        stream.insert(randpos+1,targets[t])
        istarget.insert(randpos-1,1)
        istarget.insert(randpos+1,1)
        
    for x in range(len(stream)):
        trialstructures.append([i,x, 
                        stream[x], 
                        stream[::-1][x],
                        istarget[x],
                        istarget[::-1][x],
                        ])

#now double the streams    
eventlist = [];
k=-1
c=random.randint(0,1)
for (e1,e2) in zip(random.sample(range(nsequence),nsequence),random.sample(range(nsequence),nsequence)):
    for e in (e1,e2):
        idx = [i for (i,x) in enumerate(trialstructures) if x[0]==e]
        k+=1
        eventlist+=[[k, (k+c)%2]+trialstructures[x] for x in idx]
eventlist = [[i]+x for (i,x) in enumerate(eventlist)]
eventlist = [x+[(x[-2+x[2]] and eventlist[i-2][-2+x[2]])] for i,x in enumerate(eventlist)]
eventlist = [x+[os.path.split(objectstimuli[x[5]])[1],letterstimuli[x[6]]] for x in eventlist]
headers = [['eventnumber','sequencenumber','condition','streamnumber','stimnumber',
            'objectstimnumber','letterstimnumber','objecttarget','lettertarget','is2back',
            'objectstim','letterstim','response','rt','correct','time_stimon','time_stimoff']]

def writeout(eventlist):
    with open('sub-%02i_task-rsvp_events.csv'%subjectnr,'w') as out:
        out.write('\n'.join([','.join(map(str,x)) for x in headers+eventlist]))

# =============================================================================
# %% START
# =============================================================================
try:
    if debug_windowedmode:
        win=visual.Window([700,700],units='pix')
    else:
        win=visual.Window(units='pix',fullscr=True)
    mouse = event.Mouse(visible=False)

    fixation = visual.GratingStim(win, tex=None, mask='gauss', sf=0, size=10,
        name='fixation', autoLog=False)
    feedback = visual.GratingStim(win, tex=None, mask='gauss', sf=0, size=fixation.size,
        name='feedback', autoLog=False)
    dot_cue = visual.GratingStim(win, tex=None, mask='gauss', sf=0, size=48,
        name='cue', autoLog=False, color='black')
    progresstext = visual.TextStim(win,text='',pos=(0,100),name='progresstext')
    sequencestarttext = visual.TextStim(win,text='',pos=(0,50),name='sequencestarttext')

    filesep='/'
    if sys.platform == 'win32':
        filesep='\\'
        
    screenshotnr = 0
    def take_screenshot(win):
        global screenshotnr 
        screenshotnr += 1
        win.getMovieFrame()
        win.saveMovieFrames('screenshots/screen_%05i.png'%screenshotnr)

    objectstimtex=[]
    for (i,y) in enumerate(objectstimuli):
        objectstimtex.append(visual.ImageStim(win,y,size=128,name=y.split(filesep)[1]))
    letterstimtex=[]
    for (i,y) in enumerate(letterstimuli):
        letterstimtex.append(visual.TextStim(win,height=32,text=y,name=y))

    def send_dummy_trigger(trigger_value):
        core.wait(trigger_duration)
            
    def send_real_trigger(trigger_value):
        trigger_port.setData(trigger_value)
        core.wait(trigger_duration)
        trigger_port.setData(0)
    
    if debug_usedummytriggers:
        sendtrigger = send_dummy_trigger
    else:
        trigger_port = parallel.ParallelPort(address=trigger_port)
        trigger_port.setData(0)
        sendtrigger = send_real_trigger

    nevents = eventlist[-1][0]
    nsequences = eventlist[-1][1]
    sequencenumber = -1
    for eventnr in range(len(eventlist)):
        if eventlist[eventnr][1]>sequencenumber:
            writeout(eventlist)
            sequencenumber = eventlist[eventnr][1]
            condition = eventlist[eventnr][2]
            correct=0
            
            if not debug_testsubject:
                try:
                    slack_data={'text':'pp%i seq %i/%i <@tijlgrootswagers> and <@amanda>'%(subjectnr,sequencenumber,nsequences),'channel':'#eeglab','username':'python'}
                    response = requests.post(webhook_url, data=json.dumps(slack_data),headers={'Content-Type': 'application/json'})
                except:
                    pass
                
            progresstext.text = '%i / %i'%(1+sequencenumber,1+nsequences)
            progresstext.draw()
            sequencestarttext.text = 'Respond to '+('letters' if condition else 'objects')+'\nPress any key to start the sequence'
            sequencestarttext.draw()
            fixation.draw()
            win.flip()
            k=event.waitKeys(keyList='asdfq', modifiers=False, timeStamped=True)
            if k[0][0]=='q':
                raise Exception('User pressed q')
            fixation.draw()
            time_fixon = win.flip()
            sendtrigger(trigger_sequencestart)
            while core.getTime() < time_fixon + fixationduration:pass
        
        response=0
        rt=0
        
        objectstim = objectstimtex[eventlist[eventnr][5]]
        objectstim.draw()
        correct-=1
        if correct<0:correct=0
        #if correct: dot_cue.color='green'
        #else: dot_cue.color='black'
        dot_cue.draw()
        letterstim = letterstimtex[eventlist[eventnr][6]]
        letterstim.draw()
        
        time_stimon=win.flip()
        sendtrigger(trigger_stimon)
        if debug_save_screenshots:take_screenshot(win)
        while core.getTime() < time_stimon + stimduration:pass
        time_stimoff=win.flip()
        sendtrigger(trigger_stimoff)
        if debug_save_screenshots:take_screenshot(win)
        k=event.getKeys(keyList='asdfq', modifiers=False, timeStamped=True)
        if k:
            response=k[0][0]
            rt=k[0][1]
            if response=='q':
                raise Exception('User pressed q')
            correct = any([eventlist[eventnr-x][9] for x in range(6) if eventnr-x>=0])*3
        eventlist[eventnr]+= [response, rt, int(correct==3), time_stimon, time_stimoff]   
        while core.getTime() < time_stimon + isiduration:pass

finally:
    writeout(eventlist)
    sequencestarttext.text='Experiment finished!'
    sequencestarttext.draw()
    win.flip()
    core.wait(1)
    win.close()
    exit()


