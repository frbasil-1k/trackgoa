import React from 'react';
import { useStore } from '../../store/useStore';
import type { ScreenType } from '../../store/useStore';
import { Home, Map as MapIcon, BarChart3, Heart } from 'lucide-react';

const navItems: { id: ScreenType; label: string; icon: any }[] = [
  { id: 'Home', label: 'Home', icon: Home },
  { id: 'Map', label: 'Tracking', icon: MapIcon },
  { id: 'Favorites', label: 'Saved', icon: Heart },
  { id: 'Analytics', label: 'Insights', icon: BarChart3 }
];

const BottomTabBar: React.FC = () => {
  const { currentScreen, setScreen } = useStore();

  return (
    <div style={{
      position: 'absolute',
      bottom: 0,
      left: 0,
      right: 0,
      height: '65px',
      backgroundColor: 'var(--surface)',
      borderTop: '1px solid var(--border)',
      display: 'flex',
      justifyContent: 'space-around',
      alignItems: 'center',
      zIndex: 500, // Above everything
      paddingBottom: 'env(safe-area-inset-bottom)'
    }}>
      {navItems.map((item) => {
        const Icon = item.icon;
        const isActive = currentScreen === item.id;
        
        return (
          <button
            key={item.id}
            onClick={() => setScreen(item.id)}
            style={{
              background: 'transparent',
              border: 'none',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: '4px',
              color: isActive ? 'var(--primary)' : 'var(--text-muted)',
              cursor: 'pointer',
              width: '100%'
            }}
          >
            <Icon size={24} strokeWidth={isActive ? 2.5 : 2} />
            <span style={{ fontSize: '11px', fontWeight: isActive ? 600 : 500 }}>
              {item.label}
            </span>
          </button>
        );
      })}
    </div>
  );
};

export default BottomTabBar;
