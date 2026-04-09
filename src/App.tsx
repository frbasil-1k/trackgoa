import React, { useEffect } from 'react';
import { useStore } from './store/useStore';
import { startSimulation, stopSimulation } from './simulation/SimulationEngine';

import Home from './screens/Home';
import Analytics from './screens/Analytics';
import Favorites from './screens/Favorites';
import MapViewer from './components/Map/MapViewer';
import BottomSheet from './components/BottomSheet/BottomSheet';
import FloatingControls from './components/Navigation/FloatingControls';
import BottomTabBar from './components/Navigation/BottomTabBar';
import AlertManager from './components/Alerts/AlertManager';

import './index.css';
import 'leaflet/dist/leaflet.css';

const LiveMapTracking: React.FC = () => {
  useEffect(() => {
    // Start engine on engine boot
    startSimulation();
    return () => { stopSimulation(); };
  }, []);

  return (
    <div style={{ position: 'relative', width: '100%', height: '100%', overflow: 'hidden' }}>
      <MapViewer />
      <FloatingControls />
      <BottomSheet />
    </div>
  );
};

function App() {
  const currentScreen = useStore(state => state.currentScreen);

  return (
    <div className="app-container">
      <AlertManager />
      
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        {currentScreen === 'Home' && <Home />}
        {currentScreen === 'Map' && <LiveMapTracking />}
        {currentScreen === 'Analytics' && <Analytics />}
        {currentScreen === 'Favorites' && <Favorites />}
      </div>

      <BottomTabBar />
    </div>
  );
}

export default App;
