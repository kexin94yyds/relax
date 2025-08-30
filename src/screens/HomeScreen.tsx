import React from 'react';
import { useNavigate } from 'react-router-dom';
import { BreathingMethod } from '../App';
import './HomeScreen.css';

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

const HomeScreen: React.FC = () => {
  const navigate = useNavigate();

  const handleMethodClick = (methodId: string) => {
    navigate(`/breathing/${methodId}`);
  };

  return (
    <div className="home-screen">
      <div className="container">
        <div className="header">
          <h1 className="title">选择放松方式</h1>
          <p className="subtitle">
            选择一个呼吸练习方法开始你的放松之旅
          </p>
        </div>

        <div className="methods-container">
          {breathingMethods.map((method) => (
            <div
              key={method.id}
              className="method-card"
              style={{ borderLeftColor: method.color }}
              onClick={() => handleMethodClick(method.id)}
            >
              <div className="method-header">
                <h3 className="method-name">{method.name}</h3>
                <div
                  className="color-indicator"
                  style={{ backgroundColor: method.color }}
                />
              </div>
              <p className="method-description">{method.description}</p>
              <div className="method-details">
                <span className="method-detail">吸气: {method.inhale}秒</span>
                {method.hold > 0 && (
                  <span className="method-detail">保持: {method.hold}秒</span>
                )}
                <span className="method-detail">呼气: {method.exhale}秒</span>
                <span className="method-detail">循环: {method.cycles}次</span>
              </div>
            </div>
          ))}
        </div>

        <div className="footer">
          <p className="footer-text">
            💡 提示：找一个安静的地方，舒适地坐下，专注于你的呼吸
          </p>
        </div>
      </div>
    </div>
  );
};

export default HomeScreen;
