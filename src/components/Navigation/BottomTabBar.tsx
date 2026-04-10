import React from 'react';
import { useStore } from '../../store/useStore';
import type { ScreenType } from '../../store/useStore';
import { Home, Route as RouteIcon, BarChart3, Heart, Settings } from 'lucide-react';

const navItems: { id: ScreenType; label: string; icon: any }[] = [
  { id: 'Home', label: 'Home', icon: Home },
  { id: 'Routes', label: 'Routes', icon: RouteIcon },
  { id: 'Analytics', label: 'Analytics', icon: BarChart3 },
  { id: 'Saved', label: 'Saved', icon: Heart },
  { id: 'Settings', label: 'Settings', icon: Settings }
];

const BottomTabBar: React.FC = () => {
  const { currentScreen, setScreen } = useStore();

  return (
    <div style={{
      position: 'absolute',
      bottom: 0,
      left: 0,
      right: 0,
      height: '70px',
      backgroundColor: 'var(--surface)',
      borderTop: '1px solid var(--border)',
      display: 'flex',
      justifyContent: 'space-around',
      alignItems: 'center',
      zIndex: 500, // Above everything
      paddingBottom: 'env(safe-area-inset-bottom)',
      boxShadow: '0 -4px 15px rgba(0, 0, 0, 0.03)'
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
              gap: '6px',
              color: isActive ? 'var(--accent)' : 'var(--text-muted)',
              cursor: 'pointer',
              width: '100%',
              transition: 'var(--transition)'
            }}
            className="active:scale-95 transition"
          >
            <div style={{ padding: isActive ? '4px 16px' : '4px', background: isActive ? 'rgba(37,99,235,0.1)' : 'transparent', borderRadius: 'var(--radius-full)', transition: 'var(--transition)' }}>
              <Icon size={22} strokeWidth={isActive ? 2.5 : 2} />
            </div>
            <span style={{ fontSize: '10px', fontWeight: isActive ? 700 : 500, opacity: isActive ? 1 : 0.8 }}>
              {item.label}
            </span>
          </button>
        );
      })}
    </div>
  );
};

export default BottomTabBar;
