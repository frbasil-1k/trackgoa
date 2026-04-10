import React, { useEffect, useState } from 'react';
import { useStore } from './store/useStore';
import { startSimulation, stopSimulation } from './simulation/SimulationEngine';
import { motion, AnimatePresence } from 'framer-motion';
import { CheckCircle2 } from 'lucide-react';

import Home from './screens/Home';
import Analytics from './screens/Analytics';
import Saved from './screens/Saved';
import Settings from './screens/Settings';
import RoutesList from './screens/RoutesList';
import MapViewer from './components/Map/MapViewer';
import BottomSheet from './components/BottomSheet/BottomSheet';
import FloatingControls from './components/Navigation/FloatingControls';
import BottomTabBar from './components/Navigation/BottomTabBar';
import AlertManager from './components/Alerts/AlertManager';

import './index.css';
import 'leaflet/dist/leaflet.css';

const ToastContainer: React.FC = () => {
  const [toast, setToast] = useState<{ message: string; id: number } | null>(null);

  useEffect(() => {
    const handler = (e: any) => {
      setToast({ message: e.detail.message, id: Date.now() });
      setTimeout(() => setToast(null), 3000);
    };
    window.addEventListener('app-toast', handler);
    return () => window.removeEventListener('app-toast', handler);
  }, []);

  return (
    <div style={{ position: 'absolute', top: '40px', left: 0, right: 0, zIndex: 9999, pointerEvents: 'none', display: 'flex', justifyContent: 'center' }}>
      <AnimatePresence>
        {toast && (
          <motion.div
            key={toast.id}
            initial={{ y: -50, opacity: 0, scale: 0.9 }}
            animate={{ y: 0, opacity: 1, scale: 1 }}
            exit={{ y: -20, opacity: 0, scale: 0.9 }}
            style={{
              background: 'var(--surface)',
              color: 'var(--text-main)',
              padding: '12px 20px',
              borderRadius: 'var(--radius-full)',
              boxShadow: '0 10px 25px rgba(0,0,0,0.1)',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              border: '1px solid var(--border-subtle)',
              fontWeight: 600,
              fontSize: '14px'
            }}
          >
            <CheckCircle2 size={18} className="text-success" />
            {toast.message}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

const LiveMapTracking: React.FC = () => {
  useEffect(() => {
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
      <ToastContainer />
      
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        {currentScreen === 'Home' && <Home />}
        {currentScreen === 'Map' && <LiveMapTracking />}
        {currentScreen === 'Analytics' && <Analytics />}
        {currentScreen === 'Saved' && <Saved />}
        {currentScreen === 'Settings' && <Settings />}
        {currentScreen === 'Routes' && <RoutesList />}
      </div>

      <BottomTabBar />
    </div>
  );
}

export default App;
