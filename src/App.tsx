import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import HomeScreen from './screens/HomeScreen';
import BreathingScreen from './screens/BreathingScreen';
import './App.css';

export interface BreathingMethod {
  id: string;
  name: string;
  description: string;
  inhale: number;
  hold: number;
  exhale: number;
  cycles: number;
  color: string;
}

const App: React.FC = () => {
  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" element={<HomeScreen />} />
          <Route path="/breathing/:methodId" element={<BreathingScreen />} />
        </Routes>
      </div>
    </Router>
  );
};

export default App;
