// This is from a pull request to gopacket (PR #408). If it gets merged,
// this file will no longer be necessary.
// Also see PR #477 for a ModbusTCP decoder.

// Copyright 2017 Google, Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file in the root of the source
// tree.

package layers

import (
	"encoding/binary"
	"errors"
	"strconv"

	"github.com/axsh/openvnet/vcap/utils"
	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
)

const (
	MBAPHeaderLen      int = 7
	MinModbusPacketLen int = MBAPHeaderLen + 1
)

var (
	// error message modified from the error message in the PR //
	ErrDataTooSmall = errors.New(utils.Join("the minimum Modbus packet length is ", strconv.Itoa(MinModbusPacketLen), " bytes"))
	LayerTypeModbus = gopacket.RegisterLayerType(1000, gopacket.LayerTypeMetadata{Name: "Modbus", Decoder: gopacket.DecodeFunc(decodeModbus)})
)

type MBAP struct {
	TransactionID uint16
	ProtocolID    uint16 // ProtocolType
	Length        uint16
	UnitID        uint8 // DestID
}

// Original comment not in PR: TODO: add FunctionCode dependent fields //
type Modbus struct {
	layers.BaseLayer
	MBAP
	FunctionCode uint8
	Payload      []byte
}

// Original code not found in the referenced PR
// add serialization to allow easier custom packet building
func (m *Modbus) SerializeTo(b gopacket.SerializeBuffer, opts gopacket.SerializeOptions) error {
	buf, err := b.PrependBytes(8)
	if err != nil {
		return err
	}
	binary.BigEndian.PutUint16(buf[0:2], uint16(m.TransactionID))
	binary.BigEndian.PutUint16(buf[2:4], uint16(m.ProtocolID))
	binary.BigEndian.PutUint16(buf[4:6], uint16(m.Length))
	buf[6] = m.UnitID
	buf[7] = m.FunctionCode

	return nil
} /////end of original code/////

func (m *Modbus) DecodeFromBytes(data []byte, df gopacket.DecodeFeedback) error {
	if len(data) < MinModbusPacketLen {
		return ErrDataTooSmall
	}
	m.TransactionID = binary.BigEndian.Uint16(data[0:2])
	m.ProtocolID = binary.BigEndian.Uint16(data[2:4])
	m.Length = binary.BigEndian.Uint16(data[4:6])
	m.UnitID = data[6]
	m.FunctionCode = data[7]
	m.Payload = data[7:]
	return nil
}

func (m *Modbus) LayerType() gopacket.LayerType {
	return LayerTypeModbus
}

func (m *Modbus) NextLayerType() gopacket.LayerType {
	return gopacket.LayerTypeZero
}

func (m *Modbus) CanDecode() gopacket.LayerClass {
	return LayerTypeModbus
}

/////duplicated from gopacket/layers/////
type layerDecodingLayer interface {
	gopacket.Layer
	DecodeFromBytes([]byte, gopacket.DecodeFeedback) error
	NextLayerType() gopacket.LayerType
}

func decodingLayerDecoder(d layerDecodingLayer, data []byte, p gopacket.PacketBuilder) error {
	err := d.DecodeFromBytes(data, p)
	if err != nil {
		return err
	}
	p.AddLayer(d)
	next := d.NextLayerType()
	if next == gopacket.LayerTypeZero {
		return nil
	}
	return p.NextDecoder(next)
}

/////duplicated from gopacket/layers/////

func decodeModbus(data []byte, p gopacket.PacketBuilder) error {
	if len(data) < MinModbusPacketLen {
		return ErrDataTooSmall
	}
	modbus := &Modbus{}
	return decodingLayerDecoder(modbus, data, p)
}
