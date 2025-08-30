import React, { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { BreathingMethod } from '../App';
import './BreathingScreen.css';

const breathingMethods: BreathingMethod[] = [
  {
    id: '1',
    name: '4-7-8 呼吸法',
    description: '经典的放松呼吸法：4秒吸气，7秒保持，8秒呼气',
    inhale: 4,
    hold: 7,
    exhale: 8,
    cycles: 5,
    color: '#4A90E2',
  },
  {
    id: '2',
    name: '简单放松',
    description: '简单的5秒呼吸循环，适合快速放松',
    inhale: 5,
    hold: 0,
    exhale: 5,
    cycles: 10,
    color: '#7ED321',
  },
  {
    id: '3',
    name: '深度放松',
    description: '深度呼吸：6秒吸气，3秒保持，8秒呼气',
    inhale: 6,
    hold: 3,
    exhale: 8,
    cycles: 6,
    color: '#F5A623',
  },
  {
    id: '4',
    name: '冥想呼吸',
    description: '适合冥想的缓慢呼吸：8秒吸气，4秒保持，8秒呼气',
    inhale: 8,
    hold: 4,
    exhale: 8,
    cycles: 4,
    color: '#9B59B6',
  },
  {
    id: '5',
    name: '共振呼吸',
    description: '每分钟6次呼吸：4秒吸气，6秒呼气，镇静神经系统',
    inhale: 4,
    hold: 0,
    exhale: 6,
    cycles: 8,
    color: '#E74C3C',
  },
  {
    id: '6',
    name: '晨间练习',
    description: '完整的晨间放松练习：深呼吸准备 + 身体扫描',
    inhale: 4,
    hold: 2,
    exhale: 6,
    cycles: 6,
    color: '#8E44AD',
  },
];

type BreathingPhase = 'inhale' | 'hold' | 'exhale' | 'ready' | 'finished';

const BreathingScreen: React.FC = () => {
  const { methodId } = useParams<{ methodId: string }>();
  const navigate = useNavigate();
  
  const [isActive, setIsActive] = useState(false);
  const [currentPhase, setCurrentPhase] = useState<BreathingPhase>('ready');
  const [countdown, setCountdown] = useState(0);
  const [currentCycle, setCurrentCycle] = useState(0);
  const [totalTime, setTotalTime] = useState(0);
  const [audioContext, setAudioContext] = useState<AudioContext | null>(null);
  const [soundEnabled, setSoundEnabled] = useState(true);
  
  const method = breathingMethods.find(m => m.id === methodId);

  // 初始化音频上下文
  useEffect(() => {
    const initAudio = () => {
      try {
        const ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
        setAudioContext(ctx);
      } catch (error) {
        console.log('音频上下文初始化失败:', error);
      }
    };
    
    initAudio();
    
    return () => {
      if (audioContext) {
        audioContext.close();
      }
    };
  }, []);

  const triggerVibration = useCallback(() => {
    if ('vibrate' in navigator) {
      navigator.vibrate(200);
    }
  }, []);

  // 播放不同阶段的提示音
  const playPhaseSound = useCallback((phase: BreathingPhase) => {
    if (!audioContext || !soundEnabled) return;
    
    try {
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      // 根据阶段设置不同的音调和持续时间
      let frequency = 800;
      let duration = 0.2;
      
      switch (phase) {
        case 'inhale':
          frequency = 600; // 较低的音调表示吸气
          duration = 0.3;
          break;
        case 'hold':
          frequency = 800; // 中等音调表示保持
          duration = 0.2;
          break;
        case 'exhale':
          frequency = 1000; // 较高的音调表示呼气
          duration = 0.4;
          break;
        case 'ready':
          frequency = 500;
          duration = 0.5;
          break;
        case 'finished':
          frequency = 400;
          duration = 0.8;
          break;
      }
      
      oscillator.frequency.setValueAtTime(frequency, audioContext.currentTime);
      gainNode.gain.setValueAtTime(0.15, audioContext.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + duration);
      
      oscillator.start(audioContext.currentTime);
      oscillator.stop(audioContext.currentTime + duration);
    } catch (error) {
      console.log('播放声音失败:', error);
    }
  }, [audioContext, soundEnabled]);

  // 播放倒计时提示音（最后3秒）
  const playCountdownSound = useCallback((count: number) => {
    if (!audioContext || !soundEnabled || count > 3) return;
    
    try {
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      // 倒计时音调逐渐升高
      const frequency = 400 + (4 - count) * 200;
      
      oscillator.frequency.setValueAtTime(frequency, audioContext.currentTime);
      gainNode.gain.setValueAtTime(0.1, audioContext.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.1);
      
      oscillator.start(audioContext.currentTime);
      oscillator.stop(audioContext.currentTime + 0.1);
    } catch (error) {
      console.log('播放倒计时声音失败:', error);
    }
  }, [audioContext, soundEnabled]);

  const startBreathing = () => {
    setIsActive(true);
    setCurrentCycle(1);
    setCurrentPhase('inhale');
    setCountdown(method?.inhale || 4);
    triggerVibration();
    playPhaseSound('inhale');
  };

  const stopBreathing = () => {
    setIsActive(false);
    setCurrentPhase('ready');
    setCountdown(0);
    setCurrentCycle(0);
  };

  useEffect(() => {
    if (!isActive || !method) return;

    const timer = setInterval(() => {
      setCountdown(prev => {
        // 播放倒计时提示音
        if (prev <= 3 && prev > 0) {
          playCountdownSound(prev);
        }
        
        if (prev <= 1) {
          // 当前阶段结束，进入下一阶段
          if (currentPhase === 'inhale') {
            if (method.hold > 0) {
              setCurrentPhase('hold');
              triggerVibration();
              playPhaseSound('hold');
              return method.hold;
            } else {
              setCurrentPhase('exhale');
              triggerVibration();
              playPhaseSound('exhale');
              return method.exhale;
            }
          } else if (currentPhase === 'hold') {
            setCurrentPhase('exhale');
            triggerVibration();
            playPhaseSound('exhale');
            return method.exhale;
          } else if (currentPhase === 'exhale') {
            // 一个完整循环结束
            if (currentCycle >= method.cycles) {
              setCurrentPhase('finished');
              setIsActive(false); // 停止计时器
              playPhaseSound('finished');
              return 0;
            } else {
              setCurrentCycle(prev => prev + 1);
              setCurrentPhase('inhale');
              triggerVibration();
              playPhaseSound('inhale');
              return method.inhale;
            }
          }
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [isActive, currentPhase, currentCycle, method, triggerVibration, playPhaseSound, playCountdownSound]);

  useEffect(() => {
    if (!method) {
      navigate('/');
      return;
    }
    
    // 计算总时间
    const cycleTime = method.inhale + method.hold + method.exhale;
    setTotalTime(cycleTime * method.cycles);
  }, [method, navigate]);

  if (!method) {
    return <div>加载中...</div>;
  }

  const getPhaseText = () => {
    switch (currentPhase) {
      case 'inhale':
        return '吸气';
      case 'hold':
        return '保持';
      case 'exhale':
        return '呼气';
      case 'ready':
        return '准备开始';
      case 'finished':
        return '练习完成';
      default:
        return '';
    }
  };

  const getPhaseColor = () => {
    switch (currentPhase) {
      case 'inhale':
        return '#4CAF50';
      case 'hold':
        return '#FF9800';
      case 'exhale':
        return '#2196F3';
      case 'ready':
        return method.color;
      case 'finished':
        return '#9C27B0';
      default:
        return method.color;
    }
  };

  const getProgressPercentage = () => {
    if (currentPhase === 'ready') return 0;
    if (currentPhase === 'finished') return 100;
    
    const cycleTime = method.inhale + method.hold + method.exhale;
    const completedCycles = currentCycle - 1;
    const currentPhaseTime = 
      currentPhase === 'inhale' ? method.inhale - countdown :
      currentPhase === 'hold' ? method.inhale + method.hold - countdown :
      method.inhale + method.hold + method.exhale - countdown;
    
    const totalCompleted = completedCycles * cycleTime + currentPhaseTime;
    return (totalCompleted / totalTime) * 100;
  };

  return (
    <div className="breathing-screen" style={{ backgroundColor: method.color + '10' }}>
      <div className="breathing-container">
        <div className="header">
          <button className="back-button" onClick={() => navigate('/')}>
            ← 返回
          </button>
          <h1 className="method-title">{method.name}</h1>
          <button 
            className={`sound-toggle ${soundEnabled ? 'enabled' : 'disabled'}`}
            onClick={() => setSoundEnabled(!soundEnabled)}
            title={soundEnabled ? '关闭声音' : '开启声音'}
          >
            {soundEnabled ? '🔊' : '🔇'}
          </button>
        </div>

        <div className="breathing-circle-container">
          <div 
            className="breathing-circle"
            style={{ 
              borderColor: getPhaseColor(),
              transform: `scale(${currentPhase === 'inhale' ? 1.2 : currentPhase === 'exhale' ? 0.8 : 1})`
            }}
          >
            <div className="phase-text">{getPhaseText()}</div>
            <div className="countdown">{currentPhase === 'finished' ? 0 : countdown}</div>
            <div className="cycle-info">
              第 {currentCycle} / {method.cycles} 轮
            </div>
          </div>
        </div>

        <div className="progress-container">
          <div className="progress-bar">
            <div 
              className="progress-fill"
              style={{ width: `${getProgressPercentage()}%` }}
            />
          </div>
          <div className="progress-text">
            {Math.round(getProgressPercentage())}% 完成
          </div>
        </div>

        <div className="controls">
          {!isActive && currentPhase === 'ready' && (
            <button className="start-button" onClick={startBreathing}>
              开始练习
            </button>
          )}
          
          {isActive && currentPhase !== 'finished' && (
            <button className="stop-button" onClick={stopBreathing}>
              停止练习
            </button>
          )}
          
          {currentPhase === 'finished' && (
            <div className="finished-container">
              <div className="finished-message">练习完成！</div>
              <button className="restart-button" onClick={startBreathing}>
                重新开始
              </button>
              <button className="back-home-button" onClick={() => navigate('/')}>
                返回首页
              </button>
            </div>
          )}
        </div>

        <div className="instructions">
          <h3>练习说明</h3>
          {method.id === '6' ? (
            <div>
              <h4>晨间练习步骤：</h4>
              <ol>
                <li>找一个安静舒适的地方坐下</li>
                <li>保持背部挺直，肩膀放松</li>
                <li>先进行三次深呼吸准备</li>
                <li>跟随屏幕提示进行呼吸练习</li>
                <li>练习完成后，进行身体扫描：
                  <ul>
                    <li>从头到脚感受身体各部分</li>
                    <li>注意头部、眼睛、鼻子、嘴巴的感觉</li>
                    <li>感受喉咙、肩膀、胸部、胃部的状态</li>
                    <li>观察是否有任何紧张或不适</li>
                  </ul>
                </li>
                <li>保持这种平静状态几分钟</li>
              </ol>
            </div>
          ) : (
            <ul>
              <li>找一个安静舒适的地方坐下</li>
              <li>保持背部挺直，肩膀放松</li>
              <li>跟随屏幕提示进行呼吸</li>
              <li>手机震动和声音会提醒你改变呼吸节奏</li>
              <li>不同音调的声音提示：
                <ul>
                  <li>低音调（600Hz）：吸气</li>
                  <li>中音调（800Hz）：保持</li>
                  <li>高音调（1000Hz）：呼气</li>
                  <li>倒计时最后3秒会有提示音</li>
                </ul>
              </li>
              <li>专注于你的呼吸，让思绪平静下来</li>
            </ul>
          )}
        </div>
      </div>
    </div>
  );
};

export default BreathingScreen;
